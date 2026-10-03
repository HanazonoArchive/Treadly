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
    // Logic for purchases view when created
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
    // Logic for filtered purchases view when created
  }
}
