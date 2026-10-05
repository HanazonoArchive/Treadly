import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/app_theme.dart';
import '../auth_controller.dart';

/// Controller for the My Purchases section.
class MyPurchaseController extends GetxController {
  final AuthController auth = Get.put(AuthController(), permanent: true);

  // Status counts (reactive)
  final RxInt toShipCount = 0.obs;
  final RxInt receivedCount = 0.obs;
  final RxInt returnsCount = 0.obs;
  final RxInt cancelledCount = 0.obs;

  // Active counts: if guest, always 0. If logged in, reflects actual count.
  int get activeToShip => auth.isGuest.value ? 0 : toShipCount.value;
  int get activeReceived => auth.isGuest.value ? 0 : receivedCount.value;
  int get activeReturns => auth.isGuest.value ? 0 : returnsCount.value;
  int get activeCancelled => auth.isGuest.value ? 0 : cancelledCount.value;

  @override
  void onInit() {
    super.onInit();
    if (!auth.isGuest.value && auth.userId.value.isNotEmpty) {
      loadOrderCounts(auth.userId.value);
    }
    ever(auth.userId, (String uid) {
      if (uid.isNotEmpty && !auth.isGuest.value) {
        loadOrderCounts(uid);
      } else {
        toShipCount.value = 0;
        receivedCount.value = 0;
        returnsCount.value = 0;
        cancelledCount.value = 0;
      }
    });
  }

  /// Loads live order counts for the user from Firebase Firestore `orders` collection
  Future<void> loadOrderCounts(String userId) async {
    if (userId.isEmpty) return;

    try {
      int toShip = 0;
      int received = 0;
      int returns = 0;
      int cancelled = 0;

      final snap = await FirebaseFirestore.instance
          .collection('orders')
          .where('user_id', isEqualTo: userId)
          .get();

      for (final doc in snap.docs) {
        final st = (doc.data()['status'] as String? ?? '').toLowerCase();
        if (st == 'to_ship') {
          toShip++;
        } else if (st == 'received') {
          received++;
        } else if (st == 'returns') {
          returns++;
        } else if (st == 'cancelled') {
          cancelled++;
        }
      }

      toShipCount.value = toShip;
      receivedCount.value = received;
      returnsCount.value = returns;
      cancelledCount.value = cancelled;
    } catch (e) {
      debugPrint('[MyPurchaseController] Error loading order counts from Firestore: $e');
    }
  }

  /// Navigate to all purchases with Guest protection
  void navigateToAllPurchases() {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to view your purchases and orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
  }

  /// Navigate to specific purchase status filter with Guest protection
  void navigateToPurchaseStatus(String status) {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to view $status orders.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
  }
}
