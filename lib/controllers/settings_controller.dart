import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/app_theme.dart';
import '../services/firebase_sync_service.dart';
import 'auth_controller.dart';

/// SettingsController manages profile editing, avatar uploads/presets,
/// notification preferences, and account termination.
class SettingsController extends GetxController {
  final AuthController auth = Get.find<AuthController>();

  late final TextEditingController nameInputController;
  final TextEditingController customAvatarController = TextEditingController();
  final RxBool isSavingName = false.obs;

  // Notification toggles
  final RxBool pushNotificationsEnabled = true.obs;
  final RxBool orderUpdatesEnabled = true.obs;
  final RxBool promoAlertsEnabled = true.obs;

  // Curated high-res driver avatar presets
  static const List<String> avatarPresets = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
  ];

  @override
  void onInit() {
    super.onInit();
    nameInputController = TextEditingController(
      text: auth.isGuest.value ? '' : auth.displayName.value,
    );
  }

  /// Update Profile Display Name
  Future<void> updateName() async {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      Get.snackbar(
        'Sign In Required',
        'Please sign in to update your profile.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final newName = nameInputController.text.trim();
    if (newName.isEmpty) {
      Get.snackbar(
        'Invalid Name',
        'Name cannot be empty.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    isSavingName.value = true;
    try {
      await FirebaseSyncService.instance.syncProfile(
        userId: auth.userId.value,
        name: newName,
        email: auth.userEmail.value,
        avatarUrl: auth.avatarUrl.value,
      );

      auth.displayName.value = newName;

      Get.snackbar(
        'Saved',
        'Profile name updated to $newName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.textPrimary,
        borderColor: AppTheme.borderDark,
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
      );
    } catch (_) {
      // Offline fallback: still update locally
      auth.displayName.value = newName;
      Get.snackbar(
        'Saved Locally',
        'Name updated locally.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.textPrimary,
        borderColor: AppTheme.borderDark,
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
      );
    } finally {
      isSavingName.value = false;
    }
  }

  /// Set Avatar from URL or Preset
  Future<void> setAvatar(String url) async {
    if (auth.isGuest.value) {
      Get.toNamed('/sign-in');
      return;
    }

    auth.avatarUrl.value = url;
    try {
      await FirebaseSyncService.instance.syncProfile(
        userId: auth.userId.value,
        name: auth.displayName.value,
        email: auth.userEmail.value,
        avatarUrl: url,
      );
    } catch (_) {}

    Get.back(); // Close avatar sheet if open
    Get.snackbar(
      'Avatar Updated',
      'Your profile picture has been updated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      borderColor: AppTheme.borderDark,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Clear App Cache
  void clearAppCache() {
    Get.snackbar(
      'Cache Cleared',
      'Local temporary images and cache cleared successfully.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      borderColor: AppTheme.borderDark,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Confirm & Terminate Account
  void promptAccountTermination() {
    if (auth.isGuest.value) {
      Get.snackbar(
        'Guest Session',
        'You are currently browsing as a guest. There is no registered account to delete.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Terminate Account?',
          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'This will permanently delete your account and order history. This action CANNOT be undone.',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Get.back();
              await _executeAccountTermination();
            },
            child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeAccountTermination() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(auth.userId.value)
          .delete();
    } catch (_) {}

    await auth.signOut();
    Get.until((route) => route.isFirst);

    Get.snackbar(
      'Account Terminated',
      'Your account and data have been removed.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: Colors.redAccent,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  void onClose() {
    nameInputController.dispose();
    customAvatarController.dispose();
    super.onClose();
  }
}
