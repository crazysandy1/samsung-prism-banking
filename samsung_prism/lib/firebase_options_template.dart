// COPY THIS FILE TO firebase_options.dart AND UPDATE WITH YOUR NEW CREDENTIALS
// Get new credentials from: https://console.firebase.google.com/project/samsung-prism-banking-app/settings/general

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example configuration file for Firebase options.
/// UPDATE ALL API KEYS WITH YOUR NEW FIREBASE PROJECT CREDENTIALS
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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_NEW_WEB_API_KEY_HERE',  // ← UPDATE THIS
    appId: '1:75576999025:web:8c38ed5aa6bd8682e92fd0',
    messagingSenderId: '75576999025',
    projectId: 'samsung-prism-banking-app',
    authDomain: 'samsung-prism-banking-app.firebaseapp.com',
    storageBucket: 'samsung-prism-banking-app.appspot.com',
    measurementId: 'G-YOUR_NEW_MEASUREMENT_ID',  // ← UPDATE THIS
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_NEW_ANDROID_API_KEY_HERE',  // ← UPDATE THIS
    appId: '1:75576999025:android:e7f8a301394e8fe9e92fd0',
    messagingSenderId: '75576999025',
    projectId: 'samsung-prism-banking-app',
    storageBucket: 'samsung-prism-banking-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_NEW_IOS_API_KEY_HERE',  // ← UPDATE THIS
    appId: '1:75576999025:ios:87e903976a37a3c4e92fd0',
    messagingSenderId: '75576999025',
    projectId: 'samsung-prism-banking-app',
    storageBucket: 'samsung-prism-banking-app.appspot.com',
    iosBundleId: 'com.example.samsungPrism',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_NEW_MACOS_API_KEY_HERE',  // ← UPDATE THIS
    appId: '1:75576999025:ios:87e903976a37a3c4e92fd0',
    messagingSenderId: '75576999025',
    projectId: 'samsung-prism-banking-app',
    storageBucket: 'samsung-prism-banking-app.appspot.com',
    iosBundleId: 'com.example.samsungPrism',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_NEW_WINDOWS_API_KEY_HERE',  // ← UPDATE THIS
    appId: '1:75576999025:web:2f4191890c08ecc0e92fd0',
    messagingSenderId: '75576999025',
    projectId: 'samsung-prism-banking-app',
    authDomain: 'samsung-prism-banking-app.firebaseapp.com',
    storageBucket: 'samsung-prism-banking-app.appspot.com',
    measurementId: 'G-YOUR_NEW_MEASUREMENT_ID',  // ← UPDATE THIS
  );
}
