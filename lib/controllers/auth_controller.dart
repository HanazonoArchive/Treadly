import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
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
        await _verifyRestoredSession(savedEmail ?? '');
      }
    } catch (e) {
      debugPrint('[AuthController] SharedPreferences restore note: $e');
    }
  }

  /// A cached session is only trusted if Firebase Authentication still has a
  /// signed-in user with the same email. Otherwise (signed out elsewhere,
  /// account deleted, or edited local storage) the app falls back to Guest.
  Future<void> _verifyRestoredSession(String savedEmail) async {
    try {
      final user = await fb.FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 8));
      final authEmail = user?.email?.trim().toLowerCase() ?? '';
      if (user == null || authEmail != savedEmail.trim().toLowerCase()) {
        await signOut(silent: true);
      }
    } on TimeoutException {
      // Auth state not known yet (slow start); keep the cached session.
    } catch (e) {
      debugPrint('[AuthController] Session verification note: $e');
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

  /// Sign In with Email & Password.
  /// The password is verified by Firebase Authentication; the Firestore
  /// `users` document only stores the profile (name, avatar, user_id).
  Future<bool> signIn({required String email, required String password}) async {
    isLoading.value = true;
    final cleanEmail = email.trim().toLowerCase();

    try {
      final credential = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final profile = await _loadOrCreateProfile(cleanEmail, credential.user!.uid);

      _setAuthenticatedUserDirect(
        newUserId: profile.uid,
        email: cleanEmail,
        name: profile.name,
        avatar: profile.avatar,
      );

      if (isStaff && profile.name.isNotEmpty && profile.name.toLowerCase() != 'staff') {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('latest_staff_name', profile.name);
        } catch (_) {}
        if (Get.isRegistered<InquiryController>()) {
          Get.find<InquiryController>().activeStaffDisplayName.value = profile.name;
        }
      }

      isLoading.value = false;
      _showAuthSnackbar('Welcome Back', 'Signed in as ${displayName.value}');
      return true;
    } on fb.FirebaseAuthException catch (e) {
      isLoading.value = false;
      _showAuthSnackbar('Sign In Failed', _authErrorMessage(e.code), isError: true);
      return false;
    } catch (e) {
      debugPrint('[AuthController] Sign-in error: $e');
      isLoading.value = false;
      _showAuthSnackbar('Sign In Failed', 'Could not reach the server. Check your connection and try again.', isError: true);
      return false;
    }
  }

  /// Sign Up with Email & Password.
  /// Firebase Authentication rejects emails that are already registered.
  /// Staff (@treadly.com) accounts cannot self-register; the shop
  /// administrator creates them in the Firebase console.
  Future<bool> signUp({required String email, required String password}) async {
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.endsWith('@treadly.com')) {
      _showAuthSnackbar(
        'Staff Account',
        'Staff accounts are created by the shop administrator. Please sign in instead.',
        isError: true,
      );
      return false;
    }

    isLoading.value = true;
    try {
      final credential = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      final profile = await _loadOrCreateProfile(cleanEmail, credential.user!.uid);

      _setAuthenticatedUserDirect(
        newUserId: profile.uid,
        email: cleanEmail,
        name: profile.name,
        avatar: profile.avatar,
      );

      isLoading.value = false;
      _showAuthSnackbar('Account Created', 'Welcome to Treadly, ${displayName.value}!');
      return true;
    } on fb.FirebaseAuthException catch (e) {
      isLoading.value = false;
      _showAuthSnackbar('Sign Up Failed', _authErrorMessage(e.code), isError: true);
      return false;
    } catch (e) {
      debugPrint('[AuthController] Sign-up error: $e');
      isLoading.value = false;
      _showAuthSnackbar('Sign Up Failed', 'Could not reach the server. Check your connection and try again.', isError: true);
      return false;
    }
  }

  /// Finds the Firestore profile for this email (keeping the user_id of
  /// accounts created before Firebase Authentication was added, so their
  /// existing orders stay linked) or creates one keyed by the Auth UID.
  Future<({String uid, String name, String avatar})> _loadOrCreateProfile(
    String cleanEmail,
    String authUid,
  ) async {
    final users = FirebaseFirestore.instance.collection('users');
    final snap = await users.where('email', isEqualTo: cleanEmail).limit(1).get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final data = doc.data();
      await doc.reference.set({'auth_uid': authUid}, SetOptions(merge: true));
      return (
        uid: data['user_id'] as String? ?? doc.id,
        name: data['name'] as String? ?? cleanEmail.split('@').first,
        avatar: data['avatar_url'] as String? ?? '',
      );
    }

    final name = cleanEmail.split('@').first;
    await users.doc(authUid).set({
      'user_id': authUid,
      'auth_uid': authUid,
      'email': cleanEmail,
      'name': name,
      'avatar_url': '',
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return (uid: authUid, name: name, avatar: '');
  }

  String _authErrorMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Could not reach the server. Check your connection and try again.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }

  void _showAuthSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: isError ? AppTheme.accentOrange : AppTheme.textPrimary,
      borderColor: AppTheme.borderDark,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
    );
  }

  /// Sign Out and reset local state
  Future<void> signOut({bool silent = false}) async {
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('[AuthController] Firebase sign-out note: $e');
    }
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

    if (silent) return;

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
