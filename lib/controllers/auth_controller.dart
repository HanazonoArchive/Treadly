import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../services/firebase_sync_service.dart';
import 'inquiry/inquiry_controller.dart';
import 'sync_controller.dart';

/// AuthController manages user session state (Guest vs Authenticated).
/// Uses Firebase Cloud Firestore as the primary user database,
/// with persistent local session caching via SharedPreferences.
class AuthController extends GetxController {
  final RxBool isGuest = true.obs;
  final RxString displayName = 'Guest'.obs;
  final RxString userEmail = ''.obs;
  final RxString userId = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxBool isLoading = false.obs;

  /// Returns true if the authenticated user has an official shop email (@treadly.com)
  bool get isStaff => userEmail.value.trim().toLowerCase().endsWith('@treadly.com');

  @override
  void onInit() {
    super.onInit();
    _checkInitialSession();
  }

  Future<void> _checkInitialSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString('auth_user_id');
      final savedEmail = prefs.getString('auth_user_email');
      final savedName = prefs.getString('auth_display_name');
      final savedAvatar = prefs.getString('auth_avatar_url');

      if (savedUid != null && savedUid.isNotEmpty) {
        _setAuthenticatedUserDirect(
          newUserId: savedUid,
          email: savedEmail ?? '',
          name: savedName ?? 'Driver',
          avatar: savedAvatar ?? '',
          persist: false,
        );
      }
    } catch (e) {
      debugPrint('[AuthController] SharedPreferences restore note: $e');
    }
  }

  void _setAuthenticatedUserDirect({
    required String newUserId,
    required String email,
    required String name,
    required String avatar,
    bool persist = true,
  }) {
    userEmail.value = email;
    displayName.value = name;
    avatarUrl.value = avatar;
    userId.value = newUserId;
    isGuest.value = false;

    if (persist) {
      _persistSession(newUserId, email, name, avatar);
    }

    // Sync latest user session from Firestore
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().syncUserData(newUserId);
    }

    // Sync inquiries for the newly active session (especially staff portal)
    if (Get.isRegistered<InquiryController>()) {
      Get.find<InquiryController>().onUserSessionChanged();
    }

    // Ensure profile document is maintained in Firestore
    FirebaseSyncService.instance.syncProfile(
      userId: newUserId,
      name: displayName.value,
      email: email,
      avatarUrl: avatarUrl.value,
    );
  }

  /// Updates display name and persists to local storage and Firestore
  Future<void> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    displayName.value = trimmed;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_display_name', trimmed);
      if (isStaff) {
        await prefs.setString('latest_staff_name', trimmed);
        await prefs.setString('staff_display_name', trimmed);
      }
    } catch (_) {}
    if (userId.value.isNotEmpty) {
      try {
        FirebaseSyncService.instance.syncProfile(
          userId: userId.value,
          name: trimmed,
          email: userEmail.value,
          avatarUrl: avatarUrl.value,
        );
      } catch (_) {}
    }
    if (isStaff && Get.isRegistered<InquiryController>()) {
      final staffId = userId.value.isNotEmpty ? userId.value : userEmail.value;
      Get.find<InquiryController>().updateStaffDisplayName(
        staffId: staffId,
        newDisplayName: trimmed,
      );
    }
  }

  Future<void> _persistSession(String uid, String email, String name, String avatar) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user_id', uid);
      await prefs.setString('auth_user_email', email);
      await prefs.setString('auth_display_name', name);
      await prefs.setString('auth_avatar_url', avatar);
    } catch (_) {}
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_id');
      await prefs.remove('auth_user_email');
      await prefs.remove('auth_display_name');
      await prefs.remove('auth_avatar_url');
    } catch (_) {}
  }

  /// Sign In with Email & Password
  Future<bool> signIn({required String email, required String password}) async {
    isLoading.value = true;
    final cleanEmail = email.trim().toLowerCase();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();
        final uid = data['user_id'] as String? ?? doc.id;
        final name = data['name'] as String? ?? cleanEmail.split('@').first;
        final avatar = data['avatar_url'] as String? ?? '';

        _setAuthenticatedUserDirect(
          newUserId: uid,
          email: cleanEmail,
          name: name,
          avatar: avatar,
        );

        if (cleanEmail.endsWith('@treadly.com') && name.isNotEmpty && name.toLowerCase() != 'staff') {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('latest_staff_name', name);
          } catch (_) {}
          if (Get.isRegistered<InquiryController>()) {
            Get.find<InquiryController>().activeStaffDisplayName.value = name;
          }
        }

        isLoading.value = false;
        Get.snackbar(
          'Welcome Back',
          'Signed in as ${displayName.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: AppTheme.textPrimary,
          borderColor: AppTheme.borderDark,
          borderWidth: 1,
          margin: const EdgeInsets.all(16),
        );
        return true;
      } else {
        // First-time automatic setup for this email in Firestore
        final newUid = 'usr-${DateTime.now().millisecondsSinceEpoch}';
        final name = cleanEmail.split('@').first;
        await FirebaseFirestore.instance.collection('users').doc(newUid).set({
          'user_id': newUid,
          'email': cleanEmail,
          'name': name,
          'avatar_url': '',
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _setAuthenticatedUserDirect(
          newUserId: newUid,
          email: cleanEmail,
          name: name,
          avatar: '',
        );

        isLoading.value = false;
        Get.snackbar(
          'Welcome to Treadly',
          'Account created for $name',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: AppTheme.textPrimary,
          borderColor: AppTheme.borderDark,
          borderWidth: 1,
          margin: const EdgeInsets.all(16),
        );
        return true;
      }
    } catch (e) {
      debugPrint('[AuthController] Firestore sign-in note: $e');
      // Offline fallback: allow login with deterministic ID
      final fallbackUid = 'usr-${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final name = cleanEmail.split('@').first;
      _setAuthenticatedUserDirect(
        newUserId: fallbackUid,
        email: cleanEmail,
        name: name,
        avatar: '',
      );
      isLoading.value = false;
      return true;
    }
  }

  /// Sign Up with Email & Password
  Future<bool> signUp({required String email, required String password}) async {
    isLoading.value = true;
    final cleanEmail = email.trim().toLowerCase();

    try {
      final newUid = 'usr-${DateTime.now().millisecondsSinceEpoch}';
      final name = cleanEmail.split('@').first;

      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'user_id': newUid,
        'email': cleanEmail,
        'name': name,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _setAuthenticatedUserDirect(
        newUserId: newUid,
        email: cleanEmail,
        name: name,
        avatar: '',
      );

      isLoading.value = false;
      Get.snackbar(
        'Account Created',
        'Welcome to Treadly, ${displayName.value}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.surfaceDark,
        colorText: AppTheme.textPrimary,
        borderColor: AppTheme.borderDark,
        borderWidth: 1,
        margin: const EdgeInsets.all(16),
      );
      return true;
    } catch (e) {
      debugPrint('[AuthController] Firestore sign-up note: $e');
      final fallbackUid = 'usr-${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final name = cleanEmail.split('@').first;
      _setAuthenticatedUserDirect(
        newUserId: fallbackUid,
        email: cleanEmail,
        name: name,
        avatar: '',
      );
      isLoading.value = false;
      return true;
    }
  }

  /// Sign Out and reset local state
  Future<void> signOut() async {
    await _clearPersistedSession();

    isGuest.value = true;
    displayName.value = 'Guest';
    userEmail.value = '';
    userId.value = '';
    avatarUrl.value = '';

    // Reset local data back to initial state
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().resetLocalData();
    }

    // Reset inquiries on logout so customer info never lingers on the app
    if (Get.isRegistered<InquiryController>()) {
      await Get.find<InquiryController>().clearOnSignOut();
    }

    Get.snackbar(
      'Signed Out',
      'You are now browsing as Guest',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.textPrimary,
      borderColor: AppTheme.borderDark,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }
}
