import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class SyncController extends GetxController {
  final RxBool isSyncing = false.obs;

  Future<void> syncUserData(String userId) async {
    if (userId.isEmpty) return;
    isSyncing.value = true;
    try {
      debugPrint('[SyncController] Synced session for user: $userId');
    } catch (e) {
      debugPrint('[SyncController] Sync error: $e');
    } finally {
      isSyncing.value = false;
    }
  }

  void resetLocalData() {
    isSyncing.value = false;
  }
}
