import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend_config.dart';
import '../models/tire.dart';
import 'database_service.dart';
import 'firebase_sync_service.dart';

/// TireRepository orchestrates Treadly's 3-Tier Database System:
/// 1. Cloud Database (Live): Supabase (PostgreSQL) or Firebase Firestore
/// 2. Local Database (Cache): SQLite for offline device storage
/// 3. Asset Bundle (Fallback): assets/data/tires.json (zero-failure guarantee)
class TireRepository {
  static final TireRepository instance = TireRepository._internal();
  TireRepository._internal();

  /// Fetches the catalog from the active database system
  Future<List<Tire>> fetchTires() async {
    List<Tire> tires = [];

    // 1. Try Primary Cloud Database
    if (BackendConfig.isSupabasePrimary) {
      tires = await _fetchFromSupabase();
      if (tires.isEmpty && BackendConfig.mirrorToSecondary.value) {
        tires = await _fetchFromFirestore();
      }
    } else {
      tires = await _fetchFromFirestore();
      if (tires.isEmpty && BackendConfig.mirrorToSecondary.value) {
        tires = await _fetchFromSupabase();
      }
    }

    // If cloud succeeded, cache to local SQLite for offline access
    if (tires.isNotEmpty) {
      DatabaseService.instance.cacheTires(tires);
      // Auto-heal Firestore if Firebase is primary and Firestore was empty
      if (BackendConfig.isFirebasePrimary || BackendConfig.mirrorToSecondary.value) {
        FirebaseSyncService.instance.cleanLegacyFirestoreTires();
        FirebaseSyncService.instance.syncTires(tires);
      }
      return tires;
    }

    // 2. Try Local SQLite Cache (Offline fallback)
    try {
      final cached = await DatabaseService.instance.getCachedTires();
      if (cached.isNotEmpty) {
        debugPrint('[TireRepository] Loaded ${cached.length} tires from local SQLite cache.');
        return cached;
      }
    } catch (e) {
      debugPrint('[TireRepository] SQLite read note: $e');
    }

    // 3. Fallback to local asset JSON (Zero-failure offline guarantee)
    try {
      final jsonString = await rootBundle.loadString('assets/data/tires.json');
      final fallbackList = Tire.fromJsonList(jsonString);
      debugPrint('[TireRepository] Loaded ${fallbackList.length} tires from bundled asset JSON.');
      if (fallbackList.isNotEmpty) {
        DatabaseService.instance.cacheTires(fallbackList);
        if (BackendConfig.isFirebasePrimary || BackendConfig.mirrorToSecondary.value) {
          FirebaseSyncService.instance.syncTires(fallbackList);
        }
      }
      return fallbackList;
    } catch (e) {
      debugPrint('[TireRepository] Error loading fallback tires JSON: $e');
      return [];
    }
  }

  /// Fetches tires from Supabase PostgreSQL `tires` table
  Future<List<Tire>> _fetchFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('tires')
          .select()
          .order('rating', ascending: false);

      if (response.isNotEmpty) {
        final list = response
            .map((row) => Tire.fromJson(row))
            .toList();
        final deduplicated = _deduplicateTires(list);
        debugPrint('[TireRepository] Successfully loaded ${deduplicated.length} live tires from Supabase.');
        return deduplicated;
      }
    } catch (e) {
      debugPrint('[TireRepository] Supabase fetch note: $e');
    }
    return [];
  }

  /// Fetches tires from Firebase Firestore `tires` collection
  Future<List<Tire>> _fetchFromFirestore() async {
    try {
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await FirebaseFirestore.instance
            .collection('tires')
            .orderBy('rating', descending: true)
            .get();
      } catch (_) {
        snapshot = await FirebaseFirestore.instance.collection('tires').get();
      }

      if (snapshot.docs.isNotEmpty) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Tire.fromJson(data);
        }).toList();
        final deduplicated = _deduplicateTires(list);
        debugPrint('[TireRepository] Successfully loaded ${deduplicated.length} live tires from Firestore.');
        return deduplicated;
      }
    } catch (e) {
      debugPrint('[TireRepository] Firestore fetch note: $e');
    }
    return [];
  }

  /// Deduplicates tires by normalized brand and model.
  /// Automatically discards legacy short IDs if modern models exist,
  /// and prioritizes rows with richer database attributes.
  List<Tire> _deduplicateTires(List<Tire> list) {
    const legacyIds = {
      'michelin-ps5-225-45-18',
      'michelin-ps-as4-245-40-18',
      'michelin-cup2-265-35-19',
      'continental-dws06-225-45-17',
      'continental-sc7-245-40-19',
      'pirelli-pzero-235-35-19',
      'goodyear-asym6-225-40-18',
      'bridgestone-re71rs-255-40-18',
    };

    final Map<String, Tire> uniqueTires = {};
    for (final tire in list) {
      final key = '${tire.brand.trim().toLowerCase()}_${tire.model.trim().toLowerCase()}';
      
      if (!uniqueTires.containsKey(key)) {
        uniqueTires[key] = tire;
      } else {
        final existing = uniqueTires[key]!;
        final existingIsLegacy = legacyIds.contains(existing.id);
        final currentIsLegacy = legacyIds.contains(tire.id);

        if (existingIsLegacy && !currentIsLegacy) {
          uniqueTires[key] = tire;
        } else if (!existingIsLegacy && currentIsLegacy) {
          // Keep the modern rich tire
        } else {
          // Compare richness (reviews, description)
          final existingScore = existing.reviewsCount + (existing.description != null ? 100 : 0);
          final currentScore = tire.reviewsCount + (tire.description != null ? 100 : 0);
          if (currentScore > existingScore) {
            uniqueTires[key] = tire;
          }
        }
      }
    }
    return uniqueTires.values.toList();
  }

  /// Seeds or updates Supabase/Firestore with catalog data (e.g. from admin or setup)
  Future<void> seedLiveDatabase(List<Tire> tires) async {
    try {
      final client = Supabase.instance.client;
      final supabaseRows = tires.map((t) => t.toJson()).toList();
      await client.from('tires').upsert(supabaseRows);
      debugPrint('[TireRepository] Seeded ${tires.length} tires into Supabase.');
    } catch (e) {
      debugPrint('[TireRepository] Error seeding Supabase: $e');
    }

    try {
      final firestore = FirebaseFirestore.instance;
      for (final tire in tires) {
        await firestore
            .collection('tires')
            .doc(tire.id)
            .set(tire.toJson(), SetOptions(merge: true));
      }
      debugPrint('[TireRepository] Seeded ${tires.length} tires into Firestore.');
    } catch (e) {
      debugPrint('[TireRepository] Error seeding Firestore: $e');
    }
  }

  /// Decrements stock for purchased tires across Supabase, Firestore, and SQLite
  Future<void> decrementStock({
    required String tireId,
    required int quantityDeducted,
  }) async {
    // 1. Supabase decrement
    try {
      final client = Supabase.instance.client;
      final row = await client.from('tires').select('stock').eq('id', tireId).maybeSingle();
      if (row != null) {
        final currentStock = (row['stock'] as num?)?.toInt() ?? 0;
        final newStock = (currentStock - quantityDeducted).clamp(0, 999999);
        await client.from('tires').update({'stock': newStock}).eq('id', tireId);
        debugPrint('[TireRepository] Decremented Supabase stock for $tireId to $newStock');
      }
    } catch (e) {
      debugPrint('[TireRepository] Supabase stock decrement error: $e');
    }

    // 2. Firestore decrement
    try {
      final docRef = FirebaseFirestore.instance.collection('tires').doc(tireId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final currentStock = (docSnap.data()?['stock'] as num?)?.toInt() ?? 0;
        final newStock = (currentStock - quantityDeducted).clamp(0, 999999);
        await docRef.update({'stock': newStock});
        debugPrint('[TireRepository] Decremented Firestore stock for $tireId to $newStock');
      }
    } catch (e) {
      debugPrint('[TireRepository] Firestore stock decrement error: $e');
    }

    // 3. Local SQLite decrement
    try {
      final db = await DatabaseService.instance.database;
      if (db != null) {
        final rows = await db.query('tires', columns: ['stock'], where: 'id = ?', whereArgs: [tireId]);
        if (rows.isNotEmpty) {
          final currentStock = (rows.first['stock'] as num?)?.toInt() ?? 0;
          final newStock = (currentStock - quantityDeducted).clamp(0, 999999);
          await db.update('tires', {'stock': newStock}, where: 'id = ?', whereArgs: [tireId]);
        }
      }
    } catch (e) {
      debugPrint('[TireRepository] SQLite stock decrement error: $e');
    }
  }
}
