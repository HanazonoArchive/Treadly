import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/backend_config.dart';
import '../services/firebase_sync_service.dart';
import 'profile/address_controller.dart';
import 'profile/my_purchase_controller.dart';
import 'profile/my_wallet_controller.dart';

/// SyncController synchronizes user data (wallet, vouchers, points)
/// between Supabase, Firebase Firestore, and local reactive controllers.
class SyncController extends GetxController {
  final RxBool isSyncing = false.obs;

  /// Default starter vouchers to guarantee availability
  static const List<Map<String, dynamic>> defaultVouchers = [
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

  /// Fetches the latest wallet balance and active vouchers count from primary backend.
  /// Self-heals: auto-seeds catalog vouchers and assigns them to the user if missing.
  Future<void> syncUserData(String userId) async {
    if (userId.isEmpty) return;
    isSyncing.value = true;

    try {
      // A. FIREBASE PRIMARY PATH
      if (BackendConfig.isFirebasePrimary) {
        // 1. Fetch or create Firestore wallet
        final fbWallet = await FirebaseSyncService.instance.getWallet(userId);
        if (fbWallet != null) {
          if (Get.isRegistered<MyWalletController>()) {
            final walletCtrl = Get.find<MyWalletController>();
            final num bal = fbWallet['balance'] ?? 0.0;
            final num pts = fbWallet['points'] ?? fbWallet['points_count'] ?? 0;
            walletCtrl.rawBalance.value = bal.toDouble();
            walletCtrl.pointsCount.value = pts.toInt();
          }
        } else {
          await FirebaseSyncService.instance.syncWallet(
            userId: userId,
            balance: 0.00,
            points: 0,
            vouchersCount: 3,
          );
        }

        // 2. Ensure catalog vouchers exist in Firestore
        await FirebaseSyncService.instance.seedCatalogVouchers(defaultVouchers);

        // 3. Ensure user vouchers exist in Firestore
        var fbVouchers = await FirebaseSyncService.instance.getUserVouchers(userId);
        if (fbVouchers.isEmpty) {
          await FirebaseSyncService.instance.assignUserVouchers(userId, defaultVouchers);
          fbVouchers = await FirebaseSyncService.instance.getUserVouchers(userId);
        }
        if (Get.isRegistered<MyWalletController>()) {
          final walletCtrl = Get.find<MyWalletController>();
          final count = fbVouchers.where((v) => v['is_available'] == true).length;
          walletCtrl.vouchersCount.value = count > 0 ? count : 3;
        }

        // 4. Saved delivery address
        if (Get.isRegistered<AddressController>()) {
          Get.find<AddressController>().fetchAddress(userId);
        }

        // 5. Purchases / Order counts
        if (Get.isRegistered<MyPurchaseController>()) {
          Get.find<MyPurchaseController>().loadOrderCounts(userId);
        }

        // 6. Dual-Sync mirror to Supabase if enabled
        if (BackendConfig.mirrorToSecondary.value) {
          try {
            await Supabase.instance.client.from('user_wallets').upsert({
              'user_id': userId,
              'balance': fbWallet != null ? (fbWallet['balance'] ?? 0.0) : 0.00,
              'points_count': fbWallet != null ? (fbWallet['points'] ?? 0) : 0,
              'vouchers_count': 3,
            });
          } catch (_) {}
        }
        return;
      }

      // B. SUPABASE PRIMARY PATH (with Firestore Dual-Sync Mirror)
      final client = Supabase.instance.client;

      // 1. Fetch or create wallet
      var walletRow = await client
          .from('user_wallets')
          .select('balance, points_count, vouchers_count')
          .eq('user_id', userId)
          .maybeSingle();

      if (walletRow == null) {
        // Self-heal: ensure wallet exists
        try {
          await client.from('user_wallets').insert({
            'user_id': userId,
            'balance': 0.00,
            'points_count': 0,
            'vouchers_count': 3,
          });
        } catch (_) {}
      } else if (Get.isRegistered<MyWalletController>()) {
        final walletCtrl = Get.find<MyWalletController>();
        final num bal = walletRow['balance'] ?? 0.0;
        final num pts = walletRow['points_count'] ?? 0;
        walletCtrl.rawBalance.value = bal.toDouble();
        walletCtrl.pointsCount.value = pts.toInt();
      }

      // 2. Ensure global vouchers exist in Supabase
      try {
        final catalogVouchers = await client.from('vouchers').select('id');
        if ((catalogVouchers as List).isEmpty) {
          await client.from('vouchers').upsert(defaultVouchers);
        }
      } catch (e) {
        debugPrint('[SyncController] Note seeding vouchers: $e');
      }

      // 3. Ensure this user has vouchers assigned in user_vouchers
      try {
        final userExisting = await client
            .from('user_vouchers')
            .select('id')
            .eq('user_id', userId);

        if ((userExisting as List).isEmpty) {
          // Assign active vouchers to this user
          final activeCatalog = await client
              .from('vouchers')
              .select('id')
              .eq('is_active', true);

          for (final v in (activeCatalog as List)) {
            await client.from('user_vouchers').upsert({
              'user_id': userId,
              'voucher_id': v['id'],
              'is_available': true,
            });
          }
        }
      } catch (e) {
        debugPrint('[SyncController] Note assigning user vouchers: $e');
      }

      // 4. Update local available vouchers count
      try {
        final availableList = await client
            .from('user_vouchers')
            .select('id')
            .eq('user_id', userId)
            .eq('is_available', true);

        if (Get.isRegistered<MyWalletController>()) {
          final walletCtrl = Get.find<MyWalletController>();
          final count = (availableList as List).length;
          walletCtrl.vouchersCount.value = count > 0 ? count : 3;
        }
      } catch (_) {}

      // 5. Fetch saved delivery address
      if (Get.isRegistered<AddressController>()) {
        Get.find<AddressController>().fetchAddress(userId);
      }

      // 6. Purchases / Order counts
      if (Get.isRegistered<MyPurchaseController>()) {
        Get.find<MyPurchaseController>().loadOrderCounts(userId);
      }

      // 7. Dual-Sync: Mirror wallet and catalog vouchers to Firebase Firestore
      if (BackendConfig.mirrorToSecondary.value || BackendConfig.isFirebasePrimary) {
        final walletCtrl = Get.isRegistered<MyWalletController>()
            ? Get.find<MyWalletController>()
            : null;
        await FirebaseSyncService.instance.syncWallet(
          userId: userId,
          balance: walletCtrl?.rawBalance.value ?? 0.0,
          points: walletCtrl?.pointsCount.value ?? 0,
          vouchersCount: walletCtrl?.vouchersCount.value ?? 3,
        );
        await FirebaseSyncService.instance.seedCatalogVouchers(defaultVouchers);
      }
    } catch (e) {
      debugPrint('[SyncController] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Updates the wallet balance in primary/mirrored cloud databases
  Future<bool> updateWalletBalance(String userId, double newBalance) async {
    if (userId.isEmpty) return false;
    bool success = false;

    // 1. Supabase update
    if (BackendConfig.isSupabasePrimary || BackendConfig.mirrorToSecondary.value) {
      try {
        await Supabase.instance.client.from('user_wallets').update({
          'balance': newBalance,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('user_id', userId);
        success = true;
      } catch (e) {
        debugPrint('[SyncController] Error updating balance in Supabase: $e');
      }
    }

    // 2. Firebase Firestore update
    if (BackendConfig.isFirebasePrimary || BackendConfig.mirrorToSecondary.value) {
      final walletCtrl = Get.isRegistered<MyWalletController>()
          ? Get.find<MyWalletController>()
          : null;
      await FirebaseSyncService.instance.syncWallet(
        userId: userId,
        balance: newBalance,
        points: walletCtrl?.pointsCount.value ?? 0,
        vouchersCount: walletCtrl?.vouchersCount.value ?? 3,
      );
      success = true;
    }

    return success;
  }

  /// Resets all local user counters back to zero upon logout
  void resetLocalData() {
    if (Get.isRegistered<MyWalletController>()) {
      final walletCtrl = Get.find<MyWalletController>();
      walletCtrl.rawBalance.value = 0.0;
      walletCtrl.vouchersCount.value = 0;
      walletCtrl.pointsCount.value = 0;
    }
    if (Get.isRegistered<AddressController>()) {
      Get.find<AddressController>().reset();
    }
  }
}
