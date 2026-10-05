import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tire.dart';
import 'firebase_sync_service.dart';

/// TireRepository orchestrates Treadly's Tire Catalog:
/// 1. Cloud Database (Primary Live): Firebase Cloud Firestore `tires` collection
/// 2. Asset Bundle (Offline Fallback): assets/data/tires.json (zero-failure guarantee)
class TireRepository {
  static final TireRepository instance = TireRepository._internal();
  TireRepository._internal();

  /// Fetches the catalog from Firebase Firestore with JSON asset fallback
  Future<List<Tire>> fetchTires() async {
    // 1. Try Firebase Firestore
    List<Tire> tires = await _fetchFromFirestore();

    if (tires.isNotEmpty) {
      return tires;
    }

    // 2. Fallback to local asset JSON (Zero-failure offline guarantee)
    try {
      final jsonString = await rootBundle.loadString('assets/data/tires.json');
      final fallbackList = Tire.fromJsonList(jsonString);
      debugPrint('[TireRepository] Loaded ${fallbackList.length} tires from bundled asset JSON.');
      if (fallbackList.isNotEmpty) {
        // Auto-seed Firestore in background
        FirebaseSyncService.instance.cleanLegacyFirestoreTires();
        FirebaseSyncService.instance.syncTires(fallbackList);
      }
      return fallbackList;
    } catch (e) {
      debugPrint('[TireRepository] Error loading fallback tires JSON: $e');
      return [];
    }
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

  /// Seeds or updates Firestore with catalog data
  Future<void> seedLiveDatabase(List<Tire> tires) async {
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

  /// Decrements stock for purchased tires in Firestore
  Future<void> decrementStock({
    required String tireId,
    required int quantityDeducted,
  }) async {
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
  }
}
