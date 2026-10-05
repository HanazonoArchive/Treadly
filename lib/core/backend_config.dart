import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available outsourced cloud database backends.
enum CloudBackend {
  supabase,
  firebase,
}

extension CloudBackendExtension on CloudBackend {
  String get displayName {
    switch (this) {
      case CloudBackend.supabase:
        return 'Supabase (PostgreSQL)';
      case CloudBackend.firebase:
        return 'Firebase (Cloud Firestore)';
    }
  }

  String get shortName {
    switch (this) {
      case CloudBackend.supabase:
        return 'Supabase';
      case CloudBackend.firebase:
        return 'Firebase';
    }
  }
}

/// Central configuration for Treadly's outsourced databases.
/// Persists the selected primary database (Supabase vs Firebase)
/// and dual-sync preferences across app sessions.
class BackendConfig {
  static const String _prefKeyPrimaryBackend = 'treadly_primary_cloud_backend';
  static const String _prefKeyMirrorSync = 'treadly_mirror_to_secondary';

  /// The primary cloud database provider used for reads and primary writes.
  /// Default set to Firebase since Firebase is the confirmed utilized cloud database.
  static final Rx<CloudBackend> primaryBackend = CloudBackend.firebase.obs;

  /// When true, write operations mirror to both databases in real time
  static final RxBool mirrorToSecondary = true.obs;

  static bool get isSupabasePrimary =>
      primaryBackend.value == CloudBackend.supabase;

  static bool get isFirebasePrimary =>
      primaryBackend.value == CloudBackend.firebase;

  /// Loads saved configuration from persistent device storage
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedBackend = prefs.getString(_prefKeyPrimaryBackend);
      if (savedBackend != null) {
        if (savedBackend == 'supabase') {
          primaryBackend.value = CloudBackend.supabase;
        } else {
          primaryBackend.value = CloudBackend.firebase;
        }
      } else {
        primaryBackend.value = CloudBackend.firebase;
      }

      final savedMirror = prefs.getBool(_prefKeyMirrorSync);
      if (savedMirror != null) {
        mirrorToSecondary.value = savedMirror;
      }
    } catch (_) {
      // Graceful fallback to default Firebase if offline/storage fails
      primaryBackend.value = CloudBackend.firebase;
    }
  }

  /// Sets and persists the primary backend
  static Future<void> setPrimary(CloudBackend backend) async {
    primaryBackend.value = backend;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKeyPrimaryBackend,
        backend == CloudBackend.firebase ? 'firebase' : 'supabase',
      );
    } catch (_) {}
  }

  /// Toggles and persists the mirror setting
  static Future<void> toggleMirror(bool enable) async {
    mirrorToSecondary.value = enable;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyMirrorSync, enable);
    } catch (_) {}
  }
}
