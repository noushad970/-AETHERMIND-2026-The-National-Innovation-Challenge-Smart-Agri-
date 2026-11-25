// Firebase options. The API keys are intentionally empty in this repository.
// Either paste your keys below on your own machine, or regenerate this file
// with `flutterfire configure --project=<your-firebase-project-id>`.
// Do not commit real keys to a public repository.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '',
    appId: '1:31213059991:android:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    storageBucket: 'smartagri-17066.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '',
    appId: '1:31213059991:ios:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    storageBucket: 'smartagri-17066.firebasestorage.app',
    iosBundleId: 'com.nsdtechnology.smartagribd',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '',
    appId: '1:31213059991:web:7340e7a9d2114d631b4ed2',
    messagingSenderId: '31213059991',
    projectId: 'smartagri-17066',
    authDomain: 'smartagri-17066.firebaseapp.com',
    storageBucket: 'smartagri-17066.firebasestorage.app',
  );
}
