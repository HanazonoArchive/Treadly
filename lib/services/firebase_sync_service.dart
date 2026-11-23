import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/shop_branch.dart';
import '../models/tire.dart';

/// Firestore helpers for the catalog, profiles and one-time data cleanup.
class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._internal();
  FirebaseSyncService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Writes tires to the tires collection.
  Future<void> syncTires(List<Tire> tires) async {
    try {
      for (final tire in tires) {
        await _db
            .collection('tires')
            .doc(tire.id)
            .set(tire.toJson(), SetOptions(merge: true));
      }
      debugPrint('[FirebaseSyncService] Synced ${tires.length} tires to Firestore.');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error syncing tires to Firestore: $e');
    }
  }

  /// Writes a profile to the users collection.
  Future<void> syncProfile({
    required String userId,
    required String name,
    required String email,
    required String avatarUrl,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('users').doc(userId).set({
        'user_id': userId,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirebaseSyncService] Synced profile to Firestore for $userId');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note syncing profile to Firestore: $e');
    }
  }

  /// Reads a profile from the users collection.
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading profile from Firestore: $e');
      return null;
    }
  }

  /// Deletes tires saved under old short ids.
  Future<void> cleanLegacyFirestoreTires() async {
    const legacyIds = [
      'michelin-ps5-225-45-18',
      'michelin-ps-as4-245-40-18',
      'michelin-cup2-265-35-19',
      'continental-dws06-225-45-17',
      'continental-sc7-245-40-19',
      'pirelli-pzero-235-35-19',
      'goodyear-asym6-225-40-18',
      'bridgestone-re71rs-255-40-18',
    ];
    for (final id in legacyIds) {
      try {
        await _db.collection('tires').doc(id).delete();
      } catch (_) {}
    }
    await cleanDeprecatedCollections();
  }

  /// Deletes collections from the removed wallet/voucher feature.
  Future<void> cleanDeprecatedCollections() async {
    const deprecatedCollections = [
      'user_vouchers',
      'user_wallets',
      'vouchers',
      'wallets',
    ];

    for (final col in deprecatedCollections) {
      try {
        final snapshot = await _db.collection(col).get();
        for (final doc in snapshot.docs) {
          try {
            await doc.reference.delete();
          } catch (_) {}
        }
        if (snapshot.docs.isNotEmpty) {
          debugPrint('[FirebaseSyncService] Deleted ${snapshot.docs.length} documents from $col in Firestore.');
        }
      } catch (e) {
        debugPrint('[FirebaseSyncService] Note checking $col: $e');
      }
    }
  }

  /// Pushes the catalog and an optional profile to Firestore.
  Future<Map<String, dynamic>> performFullMirrorSync({String? userId, List<Tire>? customTires}) async {
    final Map<String, dynamic> report = {};
    try {
      await cleanLegacyFirestoreTires();

      await syncFlagshipWorkshop();
      report['workshop_synced'] = ShopBranch.flagship.name;

      List<Tire> tiresToSync = customTires ?? [];
      if (tiresToSync.isEmpty) {
        try {
          final jsonString = await rootBundle.loadString('assets/data/tires.json');
          tiresToSync = Tire.fromJsonList(jsonString);
        } catch (_) {}
      }
      if (tiresToSync.isNotEmpty) {
        await syncTires(tiresToSync);
        report['tires_synced'] = tiresToSync.length;
      }

      final targetUser = (userId != null && userId.isNotEmpty) ? userId : 'demo_driver';
      await syncProfile(
        userId: targetUser,
        name: 'Demo Driver',
        email: 'driver@treadly.ph',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      );
      report['user_synced'] = targetUser;
      report['status'] = 'success';
      return report;
    } catch (e) {
      report['status'] = 'error';
      report['error'] = e.toString();
      return report;
    }
  }

  /// Writes the shop to shop_branches and removes old branch documents.
  Future<void> syncFlagshipWorkshop() async {
    try {
      await _db
          .collection('shop_branches')
          .doc(ShopBranch.flagship.id)
          .set(ShopBranch.flagship.toJson(), SetOptions(merge: true));

      const legacyBranchIds = [
        'branch-qc-main',
        'branch-makati-south',
        'branch-alabang-west',
        'branch-pasig-east',
      ];
      for (final id in legacyBranchIds) {
        try {
          await _db.collection('shop_branches').doc(id).delete();
        } catch (_) {}
      }
      debugPrint('[FirebaseSyncService] Synced Flagship Workshop & cleaned legacy branches in Firestore.');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error syncing flagship workshop to Firestore: $e');
    }
  }

  /// Writes sample data for testing.
  Future<String?> testPushLiveDemoData() async {
    try {
      await syncFlagshipWorkshop();
      // Tires
      try {
        final jsonString = await rootBundle.loadString('assets/data/tires.json');
        final catalogTires = Tire.fromJsonList(jsonString);
        for (final tire in catalogTires) {
          await _db
              .collection('tires')
              .doc(tire.id)
              .set(tire.toJson(), SetOptions(merge: true));
        }
      } catch (e) {
        debugPrint('[FirebaseSyncService] Catalog load note: $e');
      }

      // Users
      await _db.collection('users').doc('demo_driver').set({
        'user_id': 'demo_driver',
        'name': 'Demo Driver',
        'email': 'driver@treadly.ph',
        'role': 'Verified Member',
        'avatar_url':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '[FirebaseSyncService] Successfully pushed demo catalog & user to Firestore!',
      );
      return null;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error pushing demo data: $e');
      return e.toString();
    }
  }
}
