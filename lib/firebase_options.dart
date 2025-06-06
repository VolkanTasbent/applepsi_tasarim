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
    apiKey: 'AIzaSyDoMsS5AK06uNiOm39vqW80Nb-58DQltOU',
    appId: '1:20929745106:web:4cd60be8df019da9d99d0b',
    messagingSenderId: '20929745106',
    projectId: 'applepsi',
    authDomain: 'applepsi.firebaseapp.com',
    storageBucket: 'applepsi.firebasestorage.app',
    measurementId: 'G-KD7T23TXH2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2G6j7M-x53zcTrm1vSk4i95s0WxE3fpg',
    appId: '1:20929745106:android:0aeddb3bf56f868ad99d0b',
    messagingSenderId: '20929745106',
    projectId: 'applepsi',
    storageBucket: 'applepsi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDjUoUaUsaJ17NM-Cl_OMlXrjc1bZe8Wls',
    appId: '1:20929745106:ios:cf30484c78956984d99d0b',
    messagingSenderId: '20929745106',
    projectId: 'applepsi',
    storageBucket: 'applepsi.firebasestorage.app',
    iosBundleId: 'com.example.applepsiTasarim',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDjUoUaUsaJ17NM-Cl_OMlXrjc1bZe8Wls',
    appId: '1:20929745106:ios:cf30484c78956984d99d0b',
    messagingSenderId: '20929745106',
    projectId: 'applepsi',
    storageBucket: 'applepsi.firebasestorage.app',
    iosBundleId: 'com.example.applepsiTasarim',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'WINDOWS_API_KEY', // Yerine kendi anahtarınızı koyun
    appId: '1:WINDOWS_APP_ID', // Yerine kendi uygulamanızın id sini koyun
    messagingSenderId: '20929745106',
    projectId: 'applepsi',
    authDomain: 'applepsi.firebaseapp.com',
    storageBucket: 'applepsi.firebasestorage.app',
    measurementId: 'WINDOWS_MEASUREMENT_ID', // windows için olan ölçüm id sini koyun
  );
}