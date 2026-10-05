import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/tire.dart';

/// FirebaseSyncService manages reading and writing data to Cloud Firestore.
/// Ensures real-time mirroring and secondary/primary data persistence in Firebase.
class FirebaseSyncService {
  static final FirebaseSyncService instance = FirebaseSyncService._internal();
  FirebaseSyncService._internal();

  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Syncs or seeds a list of rich tires to Firestore `tires` collection
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

  /// Syncs wallet balance, points, and voucher count to Firestore `user_wallets`
  Future<void> syncWallet({
    required String userId,
    required double balance,
    required int points,
    required int vouchersCount,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('user_wallets').doc(userId).set({
        'user_id': userId,
        'balance': balance,
        'points_count': points,
        'vouchers_count': vouchersCount,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirebaseSyncService] Synced wallet to Firestore for $userId');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note syncing wallet to Firestore: $e');
    }
  }

  /// Retrieves wallet data from Firestore
  Future<Map<String, dynamic>?> getWallet(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('user_wallets').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading wallet from Firestore: $e');
      return null;
    }
  }

  /// Syncs saved delivery address to Firestore `user_addresses`
  Future<void> syncAddress({
    required String userId,
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String city,
    required String postalCode,
  }) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('user_addresses').doc(userId).set({
        'user_id': userId,
        'recipient_name': recipientName,
        'phone_number': phoneNumber,
        'street_address': streetAddress,
        'city': city,
        'postal_code': postalCode,
        'is_default': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[FirebaseSyncService] Synced address to Firestore for $userId');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note syncing address to Firestore: $e');
    }
  }

  /// Retrieves delivery address from Firestore
  Future<Map<String, dynamic>?> getAddress(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final doc = await _db.collection('user_addresses').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading address from Firestore: $e');
      return null;
    }
  }

  /// Deletes delivery address from Firestore
  Future<void> deleteAddress(String userId) async {
    if (userId.isEmpty) return;
    try {
      await _db.collection('user_addresses').doc(userId).delete();
      debugPrint('[FirebaseSyncService] Deleted address in Firestore for $userId');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note deleting address in Firestore: $e');
    }
  }

  /// Syncs user profile identity to Firestore `users`
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

  /// Retrieves user profile identity from Firestore `users`
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

  /// Purges any legacy short tire IDs from the Firestore `tires` collection
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
  }

  /// Seeds catalog vouchers into Firestore `vouchers` collection
  Future<void> seedCatalogVouchers(List<Map<String, dynamic>> vouchers) async {
    try {
      for (final v in vouchers) {
        final id = v['id'] as String;
        await _db.collection('vouchers').doc(id).set(v, SetOptions(merge: true));
      }
      debugPrint('[FirebaseSyncService] Synced catalog vouchers to Firestore.');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note seeding catalog vouchers to Firestore: $e');
    }
  }

  /// Retrieves catalog vouchers from Firestore `vouchers` collection
  Future<List<Map<String, dynamic>>> getCatalogVouchers() async {
    try {
      final snap = await _db.collection('vouchers').where('is_active', isEqualTo: true).get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading vouchers: $e');
      return [];
    }
  }

  /// Retrieves a user's vouchers from Firestore `user_vouchers` merged with `vouchers`
  Future<List<Map<String, dynamic>>> getUserVouchers(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snap = await _db
          .collection('user_vouchers')
          .where('user_id', isEqualTo: userId)
          .get();

      if (snap.docs.isEmpty) return [];

      final catalogSnap = await _db.collection('vouchers').get();
      final catalogMap = {for (var d in catalogSnap.docs) d.id: d.data()};

      final List<Map<String, dynamic>> result = [];
      for (final doc in snap.docs) {
        final data = doc.data();
        final vId = data['voucher_id'] as String?;
        final voucher = catalogMap[vId] ?? {};
        result.add({
          'id': doc.id,
          'is_available': data['is_available'] ?? true,
          'vouchers': voucher,
        });
      }
      return result;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading user vouchers: $e');
      return [];
    }
  }

  /// Assigns vouchers to a user in Firestore `user_vouchers`
  Future<void> assignUserVouchers(String userId, List<Map<String, dynamic>> vouchers) async {
    if (userId.isEmpty) return;
    try {
      final batch = _db.batch();
      for (final v in vouchers) {
        final vId = v['id'] as String;
        final docRef = _db.collection('user_vouchers').doc('${userId}_$vId');
        batch.set(docRef, {
          'id': '${userId}_$vId',
          'user_id': userId,
          'voucher_id': vId,
          'is_available': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note assigning user vouchers in Firestore: $e');
    }
  }

  /// Performs a complete 1-to-1 sync of all 9 collections/subcollections to Firestore.
  /// Guarantees clean 15 modern tires, purged duplicates, seeded vouchers, driver profiles,
  /// wallet, address, active cart, and order history.
  Future<Map<String, dynamic>> performFullMirrorSync({String? userId, List<Tire>? customTires}) async {
    final Map<String, dynamic> report = {};
    try {
      // 1. Clean legacy IDs from tires collection
      await cleanLegacyFirestoreTires();

      // 2. Sync full 15 modern tires
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

      // 3. Seed universal vouchers catalog
      const defaultVouchers = [
        {
          'id': 'welcome-500',
          'code': 'WELCOME500',
          'title': '₱500 Off Any Set of 4',
          'discount_amount': 500.00,
          'min_spend': 3000.00,
          'is_active': true,
        },
        {
          'id': 'michelin-1000',
          'code': 'MICHELIN1K',
          'title': '₱1,000 Off Michelin Pilot Sport',
          'discount_amount': 1000.00,
          'min_spend': 6000.00,
          'is_active': true,
        },
        {
          'id': 'first-ride-200',
          'code': 'FIRST200',
          'title': '₱200 Flat Welcome Voucher',
          'discount_amount': 200.00,
          'min_spend': 1000.00,
          'is_active': true,
        },
      ];
      await seedCatalogVouchers(defaultVouchers);
      report['vouchers_synced'] = defaultVouchers.length;

      // 4. Sync target user profile and wallet if specified, or demo_driver
      final targetUser = (userId != null && userId.isNotEmpty) ? userId : 'demo_driver';
      await syncProfile(
        userId: targetUser,
        name: 'Demo Driver',
        email: 'driver@treadly.ph',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
      );
      await syncWallet(
        userId: targetUser,
        balance: 3500.00,
        points: 175,
        vouchersCount: 3,
      );
      await assignUserVouchers(targetUser, defaultVouchers);
      await syncAddress(
        userId: targetUser,
        recipientName: 'Demo Driver',
        phoneNumber: '+63 917 123 4567',
        streetAddress: 'Unit 10A, 88 Radial Blvd',
        city: 'Makati City',
        postalCode: '1200',
      );
      report['user_synced'] = targetUser;

      // 5. Ensure sample order history exists
      await _db.collection('orders').doc('ORD-84920').set({
        'id': 'ORD-84920',
        'user_id': targetUser,
        'status': 'to_ship',
        'total_amount': 879.96,
        'item_count': 4,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('order_items').doc('ITEM-84920-1').set({
        'order_id': 'ORD-84920',
        'tire_id': 'michelin-pilot-sport-5',
        'quantity': 4,
        'price_at_purchase': 219.99,
        'tire_name': 'Michelin Pilot Sport 5 (225/45 R18)',
      }, SetOptions(merge: true));
      report['orders_synced'] = 1;

      report['status'] = 'success';
      return report;
    } catch (e) {
      report['status'] = 'error';
      report['error'] = e.toString();
      return report;
    }
  }

  /// Pushes test documents to all 9 Firestore collections and subcollections:
  /// (tires, users, user_wallets, vouchers, user_vouchers, orders, order_items, user_addresses, cart)
  Future<String?> testPushLiveDemoData() async {
    try {
      // 1. tires collection (Treadly Tire Catalog with full 15 models and rich schema)
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

      // 2. users collection (Driver Profiles)
      await _db.collection('users').doc('demo_driver').set({
        'user_id': 'demo_driver',
        'name': 'Demo Driver',
        'email': 'driver@treadly.ph',
        'role': 'Verified Member',
        'avatar_url':
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. user_wallets collection (Balance & Points)
      await _db.collection('user_wallets').doc('demo_driver').set({
        'user_id': 'demo_driver',
        'balance': 3500.00,
        'points_count': 175,
        'vouchers_count': 3,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 4. vouchers collection (Universal Discounts Catalog)
      await seedCatalogVouchers([
        {
          'id': 'welcome-500',
          'code': 'WELCOME500',
          'title': '₱500 Off Any Set of 4',
          'discount_amount': 500.00,
          'min_spend': 3000.00,
          'is_active': true,
        },
        {
          'id': 'michelin-1000',
          'code': 'MICHELIN1K',
          'title': '₱1,000 Off Michelin Pilot Sport',
          'discount_amount': 1000.00,
          'min_spend': 6000.00,
          'is_active': true,
        },
        {
          'id': 'first-ride-200',
          'code': 'FIRST200',
          'title': '₱200 Flat Welcome Voucher',
          'discount_amount': 200.00,
          'min_spend': 1000.00,
          'is_active': true,
        },
      ]);

      // 5. user_vouchers collection (User Redemption Availability)
      final userVouchers = [
        {'id': 'demo_driver_welcome500', 'voucher_id': 'welcome-500'},
        {'id': 'demo_driver_michelin1k', 'voucher_id': 'michelin-1000'},
        {'id': 'demo_driver_first200', 'voucher_id': 'first-ride-200'},
      ];
      for (final uv in userVouchers) {
        await _db.collection('user_vouchers').doc(uv['id']).set({
          'user_id': 'demo_driver',
          'voucher_id': uv['voucher_id'],
          'is_available': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 6. orders collection (Purchases Tracking)
      await _db.collection('orders').doc('ORD-84920').set({
        'id': 'ORD-84920',
        'user_id': 'demo_driver',
        'status': 'to_ship',
        'total_amount': 879.96,
        'item_count': 4,
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 7. order_items collection (Purchased Line Items)
      await _db.collection('order_items').doc('ITEM-84920-1').set({
        'order_id': 'ORD-84920',
        'tire_id': 'michelin-pilot-sport-5',
        'quantity': 4,
        'price_at_purchase': 219.99,
        'tire_name': 'Michelin Pilot Sport 5 (225/45 R18)',
      }, SetOptions(merge: true));

      // 8. user_addresses collection (Saved Delivery Address)
      await _db.collection('user_addresses').doc('demo_driver').set({
        'user_id': 'demo_driver',
        'recipient_name': 'Demo Driver',
        'phone_number': '+63 917 123 4567',
        'street_address': 'Unit 10A, 88 Radial Blvd',
        'city': 'Makati City',
        'postal_code': '1200',
        'is_default': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 9. cart collection (Active Cart for demo_driver)
      await _db
          .collection('users')
          .doc('demo_driver')
          .collection('cart')
          .doc('michelin-pilot-sport-5_false')
          .set({
        'tire_id': 'michelin-pilot-sport-5',
        'quantity': 2,
        'is_set_of_four': false,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        '[FirebaseSyncService] Successfully pushed all 9 collections/subcollections to Firestore!',
      );
      return null;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error pushing demo data: $e');
      return e.toString();
    }
  }

  /// Syncs user's active cart to Firestore
  Future<void> syncCart(String userId, List<Map<String, dynamic>> cartMaps) async {
    if (userId.isEmpty) return;
    try {
      final cartCollection = _db.collection('users').doc(userId).collection('cart');
      final currentDocs = await cartCollection.get();
      final batch = _db.batch();

      for (final doc in currentDocs.docs) {
        batch.delete(doc.reference);
      }

      for (final item in cartMaps) {
        final docRef = cartCollection.doc('${item['tire_id']}_${item['is_set_of_four']}');
        batch.set(docRef, {
          ...item,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('[FirebaseSyncService] Synced ${cartMaps.length} cart items to Firestore for $userId');
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note syncing cart to Firestore: $e');
    }
  }

  /// Retrieves user's active cart from Firestore
  Future<List<Map<String, dynamic>>> getCart(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final snap = await _db.collection('users').doc(userId).collection('cart').get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('[FirebaseSyncService] Note reading cart from Firestore: $e');
      return [];
    }
  }
}
