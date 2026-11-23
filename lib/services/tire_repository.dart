import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tire.dart';
import 'firebase_sync_service.dart';

/// Loads the tire catalog from Firestore, falling back to
/// assets/data/tires.json when Firestore is empty or offline.
class TireRepository {
  static final TireRepository instance = TireRepository._internal();
  TireRepository._internal();

  Future<List<Tire>> fetchTires() async {
    List<Tire> tires = await _fetchFromFirestore();

    List<Tire> fallbackList = [];
    try {
      final jsonString = await rootBundle.loadString('assets/data/tires.json');
      fallbackList = Tire.fromJsonList(jsonString);
    } catch (e) {
      debugPrint('[TireRepository] Error loading fallback tires JSON: $e');
    }

    // Firestore is missing tires from the bundled catalog: upload them
    // in the background and use the bundled list for now.
    if (fallbackList.isNotEmpty && tires.length < fallbackList.length) {
      debugPrint('[TireRepository] Expanded catalog detected (${fallbackList.length} tires vs ${tires.length} in Firestore). Syncing to Firestore...');
      FirebaseSyncService.instance.cleanLegacyFirestoreTires();
      FirebaseSyncService.instance.syncTires(fallbackList);
      return fallbackList;
    }

    if (tires.isNotEmpty) {
      return tires;
    }

    return fallbackList;
  }

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

  /// Removes duplicates and tires saved under old short ids.
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
      if (legacyIds.contains(tire.id.toLowerCase())) continue;

      final key = tire.id.isNotEmpty
          ? tire.id.trim().toLowerCase()
          : '${tire.brand.trim().toLowerCase()}_${tire.model.trim().toLowerCase()}_${tire.rimSize}_${tire.width}';
      
      if (!uniqueTires.containsKey(key)) {
        uniqueTires[key] = tire;
      } else {
        final existing = uniqueTires[key]!;
        final existingScore = existing.reviewsCount + (existing.description != null ? 100 : 0);
        final currentScore = tire.reviewsCount + (tire.description != null ? 100 : 0);
        if (currentScore > existingScore) {
          uniqueTires[key] = tire;
        }
      }
    }
    return uniqueTires.values.toList();
  }

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

  /// Not called yet; stock is adjusted by staff.
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

  Future<void> updateTire(Tire tire) async {
    try {
      await FirebaseFirestore.instance
          .collection('tires')
          .doc(tire.id)
          .set(tire.toJson(), SetOptions(merge: true));
      debugPrint('[TireRepository] Successfully updated tire ${tire.id} in Firestore.');
    } catch (e) {
      debugPrint('[TireRepository] Error updating tire ${tire.id}: $e');
    }
  }
}
