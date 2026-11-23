import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Treadly.
/// Configuration generated from Firebase Console for project 'treadly-9dd72'.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1mPzwhK80kSYSTsOuv_HaQfTMMFRD56Q',
    appId: '1:574972738156:web:ac945a1294a12bbd4c7649',
    messagingSenderId: '574972738156',
    projectId: 'treadly-9dd72',
    authDomain: 'treadly-9dd72.firebaseapp.com',
    storageBucket: 'treadly-9dd72.firebasestorage.app',
    measurementId: 'G-NF69WX3DR8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDR7D6EwKmsr4x1-VuLquOGAylLB5JbRak',
    appId: '1:574972738156:android:f1321023d24b4b174c7649',
    messagingSenderId: '574972738156',
    projectId: 'treadly-9dd72',
    storageBucket: 'treadly-9dd72.firebasestorage.app',
  );

  static const FirebaseOptions ios = web;
}
