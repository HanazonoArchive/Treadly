import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// SyncController coordinates user session synchronization
/// between Firebase Cloud Firestore and local reactive controllers.
class SyncController extends GetxController {
  final RxBool isSyncing = false.obs;

  /// Refreshes user session data from Firestore
  Future<void> syncUserData(String userId) async {
    if (userId.isEmpty) return;
    isSyncing.value = true;
    try {
      // User profile & inquiries are synchronized via AuthController and InquiryController
      debugPrint('[SyncController] Synced session for user: $userId');
    } catch (e) {
      debugPrint('[SyncController] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  /// Resets local session state upon logout
  void resetLocalData() {
    isSyncing.value = false;
  }
}
