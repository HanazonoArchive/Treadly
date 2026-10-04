import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';

/// NavigationService handles hierarchy-aware navigation.
/// Resolves deep-link/refresh navigation traps and prevents
/// GetX snackbar overlays from blocking view popping.
class NavigationService {
  /// Safely navigates back:
  /// 1. Closes any lingering snackbars so they do not absorb clicks.
  /// 2. If the current Navigator has a parent route, pops it directly.
  /// 3. If the user refreshed or directly opened a sub-page (empty route stack),
  ///    gracefully returns to the Home view and selects the target tab (default: 3 for Profile).
  static void goBackOrHome(BuildContext context, {int targetTab = 3}) {
    // 1. Dismiss any open snackbars immediately so they don't capture taps
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    // 2. Check if the Navigator can pop a view route
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // 3. Fallback: Return to root HomeView and switch to target tab
      Get.offAllNamed('/');
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeTab(targetTab);
      }
    }
  }
}
