import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_theme.dart';
import '../core/backend_config.dart';
import '../services/firebase_sync_service.dart';
import 'cart/cart_controller.dart';
import 'sync_controller.dart';

/// AuthController manages user session state (Guest vs Authenticated).
/// Integrates with Supabase Auth, Firebase Firestore, and local persistent session.
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

  Future<void> _checkInitialSession() async {
    // 1. Check Supabase session
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && session.user.email != null) {
        _setAuthenticatedUser(session.user);
        return;
      }
    } catch (_) {}

    // 2. Fallback to persisted session from SharedPreferences
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

  void _setAuthenticatedUser(User user) {
    _setAuthenticatedUserDirect(
      newUserId: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Driver',
      avatar: user.userMetadata?['avatar_url'] as String? ?? '',
    );
  }

  void _setAuthenticatedUserDirect({
    required String newUserId,
    required String email,
    required String name,
    required String avatar,
    bool persist = true,
  }) {
    isGuest.value = false;
    userId.value = newUserId;
    userEmail.value = email;
    avatarUrl.value = avatar;
    displayName.value = name;

    if (persist) {
      _persistSession(newUserId, email, name, avatar);
    }

    // Sync latest user wallet & vouchers from primary DB
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().syncUserData(newUserId);
    }

    // Sync active shopping cart from primary DB
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().syncWithUser(newUserId);
    }

    // Mirror registered user profile into Firebase Firestore
    if (BackendConfig.mirrorToSecondary.value || BackendConfig.isFirebasePrimary) {
      FirebaseSyncService.instance.syncProfile(
        userId: newUserId,
        name: displayName.value,
        email: email,
        avatarUrl: avatarUrl.value,
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

    // 1. If Firebase is primary, attempt Firestore authentication first
    if (BackendConfig.isFirebasePrimary) {
      final ok = await _tryFirestoreSignIn(cleanEmail);
      if (ok) {
        isLoading.value = false;
        Get.snackbar(
          'Welcome Back',
          'Signed in as ${displayName.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return true;
      }
    }

    // 2. Supabase Auth attempt
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: cleanEmail,
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
    } catch (e) {
      debugPrint('[AuthController] Supabase sign-in note: $e');
      // 3. Fallback to Firestore if Supabase was attempted and failed
      final ok = await _tryFirestoreSignIn(cleanEmail);
      if (ok) {
        isLoading.value = false;
        Get.snackbar(
          'Welcome Back',
          'Signed in as ${displayName.value}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return true;
      }
    }

    isLoading.value = false;
    Get.snackbar(
      'Sign In Failed',
      'Please check your email and credentials.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.accentOrange,
      margin: const EdgeInsets.all(16),
    );
    return false;
  }

  /// Sign Up with Email & Password
  Future<bool> signUp({required String email, required String password}) async {
    isLoading.value = true;
    final cleanEmail = email.trim().toLowerCase();

    // 1. If Firebase is primary, create user directly in Firestore
    if (BackendConfig.isFirebasePrimary) {
      final ok = await _tryFirestoreSignUp(cleanEmail);
      if (ok) {
        isLoading.value = false;
        Get.snackbar(
          'Account Created',
          'Welcome to Treadly, ${displayName.value}!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return true;
      }
    }

    // 2. Supabase Auth attempt
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: cleanEmail,
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
    } catch (e) {
      debugPrint('[AuthController] Supabase sign-up note: $e');
      // 3. Fallback to Firestore
      final ok = await _tryFirestoreSignUp(cleanEmail);
      if (ok) {
        isLoading.value = false;
        Get.snackbar(
          'Account Created',
          'Welcome to Treadly, ${displayName.value}!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppTheme.surfaceDark,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
        return true;
      }
    }

    isLoading.value = false;
    Get.snackbar(
      'Sign Up Failed',
      'Could not complete registration. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.surfaceDark,
      colorText: AppTheme.accentOrange,
      margin: const EdgeInsets.all(16),
    );
    return false;
  }

  Future<bool> _tryFirestoreSignIn(String email) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data();
        final uid = data['user_id'] as String? ?? doc.id;
        final name = data['name'] as String? ?? email.split('@').first;
        final avatar = data['avatar_url'] as String? ?? '';
        _setAuthenticatedUserDirect(
          newUserId: uid,
          email: email,
          name: name,
          avatar: avatar,
        );
        return true;
      }
    } catch (e) {
      debugPrint('[AuthController] Firestore sign-in note: $e');
    }
    return false;
  }

  Future<bool> _tryFirestoreSignUp(String email) async {
    try {
      final newUid = 'usr-${DateTime.now().millisecondsSinceEpoch}';
      final name = email.split('@').first;
      await FirebaseFirestore.instance.collection('users').doc(newUid).set({
        'user_id': newUid,
        'email': email,
        'name': name,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _setAuthenticatedUserDirect(
        newUserId: newUid,
        email: email,
        name: name,
        avatar: '',
      );
      return true;
    } catch (e) {
      debugPrint('[AuthController] Firestore sign-up note: $e');
      return false;
    }
  }

  /// Sign Out and reset local state
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await _clearPersistedSession();

    isGuest.value = true;
    displayName.value = 'Guest';
    userEmail.value = '';
    userId.value = '';
    avatarUrl.value = '';

    // Reset local wallet, vouchers, and points back to 0!
    if (Get.isRegistered<SyncController>()) {
      Get.find<SyncController>().resetLocalData();
    }

    // Reset shopping cart for guest session
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clearCart();
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
