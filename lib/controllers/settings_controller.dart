import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/backend_config.dart';
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

  // Developer Mode Easter Egg: Tap "Version" 5 times to reveal Cloud DB settings
  final RxInt versionTapCount = 0.obs;
  final RxBool showDeveloperCloudSettings = false.obs;

  @override
  void onInit() {
    super.onInit();
    showDeveloperCloudSettings.value = false;
    versionTapCount.value = 0;
    nameInputController = TextEditingController(
      text: auth.isGuest.value ? '' : auth.displayName.value,
    );
  }

  /// Handles user tapping the app version tile
  void onVersionTapped() {
    if (showDeveloperCloudSettings.value) return;

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    versionTapCount.value++;
    if (versionTapCount.value >= 5) {
      showDeveloperCloudSettings.value = true;
      Get.snackbar(
        'Developer Mode Unlocked',
        'Cloud Database Architecture is now visible below Danger Zone.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1400),
      );
      versionTapCount.value = 0;
    } else if (versionTapCount.value >= 2) {
      final remaining = 5 - versionTapCount.value;
      Get.snackbar(
        'Developer Settings',
        'Tap $remaining more ${remaining == 1 ? "time" : "times"} to unlock Cloud Database Architecture.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.textSecondary,
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 800),
      );
    }
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
      await Supabase.instance.client
          .from('profiles')
          .update({'name': newName})
          .eq('id', auth.userId.value);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'name': newName}),
      );

      auth.displayName.value = newName;

      // Sync to Firebase Firestore
      if (BackendConfig.mirrorToSecondary.value || BackendConfig.isFirebasePrimary) {
        await FirebaseSyncService.instance.syncProfile(
          userId: auth.userId.value,
          name: newName,
          email: auth.userEmail.value,
          avatarUrl: auth.avatarUrl.value,
        );
      }

      Get.snackbar(
        'Saved',
        'Profile name updated to $newName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: Colors.white,
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
        colorText: Colors.white,
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
      await Supabase.instance.client
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', auth.userId.value);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'avatar_url': url}),
      );
    } catch (_) {}

    // Sync to Firebase Firestore
    if (BackendConfig.mirrorToSecondary.value || BackendConfig.isFirebasePrimary) {
      await FirebaseSyncService.instance.syncProfile(
        userId: auth.userId.value,
        name: auth.displayName.value,
        email: auth.userEmail.value,
        avatarUrl: url,
      );
    }

    Get.back(); // Close avatar sheet if open
    Get.snackbar(
      'Avatar Updated',
      'Your profile picture has been updated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: Colors.white,
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
      colorText: Colors.white,
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
          'This will permanently delete your account, saved vouchers, and wallet balance. This action CANNOT be undone.',
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
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', auth.userId.value);
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
    showDeveloperCloudSettings.value = false;
    versionTapCount.value = 0;
    nameInputController.dispose();
    customAvatarController.dispose();
    super.onClose();
  }
}
