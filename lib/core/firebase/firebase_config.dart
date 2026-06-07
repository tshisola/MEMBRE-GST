import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options for IFCM Lubumbashi (project: membremedia).
class FirebaseConfig {
  FirebaseConfig._();

  static const String projectId = 'membremedia';
  static const String storageBucket = 'membremedia.firebasestorage.app';
  static const String messagingSenderId = '622278481977';

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
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAW3Cd7Cp_nbh3yUKBFDY7BD9nLDyoNAlc',
    appId: '1:622278481977:android:REPLACE_ME',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW3Cd7Cp_nbh3yUKBFDY7BD9nLDyoNAlc',
    appId: '1:622278481977:ios:REPLACE_ME',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.example.ifcmMembership',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAW3Cd7Cp_nbh3yUKBFDY7BD9nLDyoNAlc',
    appId: '1:622278481977:web:73d5628a0505f8c1ff15e8',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    authDomain: '$projectId.firebaseapp.com',
    databaseURL: 'https://membremedia-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAW3Cd7Cp_nbh3yUKBFDY7BD9nLDyoNAlc',
    appId: '1:622278481977:windows:REPLACE_ME',
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
