import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../services/firebase_sync_service.dart';
import 'profile/address_controller.dart';
import 'profile/my_purchase_controller.dart';
import 'profile/my_wallet_controller.dart';

/// SyncController synchronizes user data (wallet, vouchers, points)
/// between Firebase Cloud Firestore and local reactive controllers.
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

  /// Fetches the latest wallet balance and active vouchers count from Firebase Firestore.
  /// Self-heals: auto-seeds catalog vouchers and assigns them to the user if missing.
  Future<void> syncUserData(String userId) async {
    if (userId.isEmpty) return;
    isSyncing.value = true;

    try {
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
    } catch (e) {
      debugPrint('[SyncController] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Updates the wallet balance in Firebase Firestore
  Future<bool> updateWalletBalance(String userId, double newBalance) async {
    if (userId.isEmpty) return false;
    try {
      final walletCtrl = Get.isRegistered<MyWalletController>()
          ? Get.find<MyWalletController>()
          : null;
      await FirebaseSyncService.instance.syncWallet(
        userId: userId,
        balance: newBalance,
        points: walletCtrl?.pointsCount.value ?? 0,
        vouchersCount: walletCtrl?.vouchersCount.value ?? 3,
      );
      return true;
    } catch (e) {
      debugPrint('[SyncController] Error updating balance in Firestore: $e');
      return false;
    }
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
