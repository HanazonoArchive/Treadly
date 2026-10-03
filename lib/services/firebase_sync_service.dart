import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  /// Pushes test documents to ALL 8 Firestore collections matching Supabase 1:1:
  /// (tires, users, user_wallets, vouchers, user_vouchers, orders, order_items, user_addresses)
  Future<String?> testPushLiveDemoData() async {
    try {
      // 1. tires collection (Treadly Tire Catalog)
      final sampleTires = [
        {
          'id': 'michelin-ps5-225-45-18',
          'brand': 'Michelin',
          'model': 'Pilot Sport 5',
          'size': '225/45 R18',
          'width': 225,
          'aspect_ratio': 45,
          'rim_size': 18,
          'category': 'Summer',
          'price': 219.99,
          'is_whitelisted': true,
        },
        {
          'id': 'continental-dws06-225-45-17',
          'brand': 'Continental',
          'model': 'ExtremeContact DWS06 Plus',
          'size': '225/45 R17',
          'width': 225,
          'aspect_ratio': 45,
          'rim_size': 17,
          'category': 'All-Season',
          'price': 184.99,
          'is_whitelisted': true,
        },
        {
          'id': 'pirelli-pzero-235-35-19',
          'brand': 'Pirelli',
          'model': 'P Zero PZ4',
          'size': '235/35 R19',
          'width': 235,
          'aspect_ratio': 35,
          'rim_size': 19,
          'category': 'Summer',
          'price': 269.99,
          'is_whitelisted': true,
        },
        {
          'id': 'bridgestone-re71rs-255-40-18',
          'brand': 'Bridgestone',
          'model': 'Potenza RE-71RS',
          'size': '255/40 R18',
          'width': 255,
          'aspect_ratio': 40,
          'rim_size': 18,
          'category': 'Track / Summer',
          'price': 295.00,
          'is_whitelisted': true,
        },
      ];

      for (final tire in sampleTires) {
        await _db
            .collection('tires')
            .doc(tire['id'] as String)
            .set(tire, SetOptions(merge: true));
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
        'tire_id': 'michelin-ps5-225-45-18',
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

      debugPrint(
        '[FirebaseSyncService] Successfully pushed all 8 collections to Firestore!',
      );
      return null;
    } catch (e) {
      debugPrint('[FirebaseSyncService] Error pushing demo data: $e');
      return e.toString();
    }
  }
}
