// Firebase options. API keys are not stored in this repository: they are read
// from assets/env/app.env (see lib/core/config/env.dart).
// Do not commit real keys to a public repository.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

import 'core/config/env.dart';

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
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform. '
          'Run `flutterfire configure` to regenerate lib/firebase_options.dart.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: Env.value(
      'FIREBASE_ANDROID_API_KEY',
      const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
    ),
    appId: '1:31213059991:android:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    storageBucket: 'smartagri-17066.firebasestorage.app',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: Env.value(
      'FIREBASE_IOS_API_KEY',
      const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
    ),
    appId: '1:31213059991:ios:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    storageBucket: 'smartagri-17066.firebasestorage.app',
    iosBundleId: 'com.nsdtechnology.smartagribd',
  );

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: Env.value(
      'FIREBASE_WEB_API_KEY',
      const String.fromEnvironment('FIREBASE_WEB_API_KEY'),
    ),
    appId: '1:31213059991:web:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    authDomain: 'smartagri-17066.firebaseapp.com',
    storageBucket: 'smartagri-17066.firebasestorage.app',
  );
}
