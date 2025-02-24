// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyBonyFckzn65FqMEF0fTMa5zwhmjLxWYes',
    appId: '1:557396719050:web:ce1017c1b6c49945460b33',
    messagingSenderId: '557396719050',
    projectId: 'webrtctest-15ae8',
    authDomain: 'webrtctest-15ae8.firebaseapp.com',
    storageBucket: 'webrtctest-15ae8.firebasestorage.app',
    measurementId: 'G-L8CXJN8EKQ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAjr2ppNMm2pxK1ATQoOBZ30QeAMqikL6M',
    appId: '1:557396719050:android:3275032a41f4158b460b33',
    messagingSenderId: '557396719050',
    projectId: 'webrtctest-15ae8',
    storageBucket: 'webrtctest-15ae8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmS1f6UZHCaTmg2eJGh82crn2QJm0ofSM',
    appId: '1:557396719050:ios:ec2e796b41ffb3f2460b33',
    messagingSenderId: '557396719050',
    projectId: 'webrtctest-15ae8',
    storageBucket: 'webrtctest-15ae8.firebasestorage.app',
    iosBundleId: 'com.ezil.webRtc',
  );
}
