import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';

/// Back navigation that also works after a page refresh on web.
class NavigationService {
  /// Closes snackbars (they block taps), pops if possible, otherwise goes
  /// to Home and opens [targetTab] (default: Profile).
  static void goBackOrHome(BuildContext context, {int targetTab = 3}) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Nothing to pop (e.g. after a refresh): go to Home
      Get.offAllNamed('/');
      if (Get.isRegistered<NavigationController>()) {
        Get.find<NavigationController>().changeTab(targetTab);
      }
    }
  }
}
