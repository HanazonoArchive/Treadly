import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/backend_config.dart';
import '../services/firebase_sync_service.dart';
import 'sync_controller.dart';

/// AuthController manages user session state (Guest vs Authenticated).
/// Integrates with Supabase Auth and coordinates with SyncController.
class AuthController extends GetxController {
  final RxBool isGuest = true.obs;
  final RxString displayName = 'Guest'.obs;
  final RxString userEmail = ''.obs;
  final RxString userId = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialSession();
  }

  void _checkInitialSession() {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.email != null) {
        _setAuthenticatedUser(session.user);
      }
    } catch (_) {
      // Supabase may not be initialized yet in test/offline environments
    }
  }

  void _setAuthenticatedUser(User user) {
    isGuest.value = false;
    userId.value = user.id;
    userEmail.value = user.email ?? '';
    avatarUrl.value = user.userMetadata?['avatar_url'] as String? ?? '';
    displayName.value = user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Driver';

    // Sync latest user wallet & vouchers from Supabase
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().syncUserData(user.id);
    }

    // Mirror registered user profile into Firebase Firestore
    if (BackendConfig.mirrorToSecondary.value || BackendConfig.isFirebasePrimary) {
      FirebaseSyncService.instance.syncProfile(
        userId: user.id,
        name: displayName.value,
        email: user.email ?? '',
        avatarUrl: avatarUrl.value,
      );
    }
  }

  /// Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _setAuthenticatedUser(user);
        Get.snackbar(
          'Welcome Back',
          'Signed in as ${displayName.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        isLoading.value = false;
        return true;
      }
      isLoading.value = false;
      return false;
    } on AuthException catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Sign In Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }
  }

  /// Sign Up with Email & Password
  Future<bool> signUp({required String email, required String password}) async {
    isLoading.value = true;
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _setAuthenticatedUser(user);
        Get.snackbar(
          'Account Created',
          'Welcome to Treadly, ${displayName.value}!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        isLoading.value = false;
        return true;
      }
      isLoading.value = false;
      return false;
    } on AuthException catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Sign Up Failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.accentOrange,
        margin: const EdgeInsets.all(16),
      );
      return false;
    }
  }

  /// Sign Out and reset local state
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    isGuest.value = true;
    displayName.value = 'Guest';
    userEmail.value = '';
    userId.value = '';
    avatarUrl.value = '';

    // Reset local wallet, vouchers, and points back to 0!
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().resetLocalData();
    }

    Get.snackbar(
      'Signed Out',
      'You are now browsing as Guest',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }
}
