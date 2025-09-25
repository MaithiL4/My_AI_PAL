// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyAVbJhOOjCQIqArj0i8c5_iblElvjp0T-Y',
    authDomain: 'my-ai-pal-6e97a.firebaseapp.com',
    projectId: 'my-ai-pal-6e97a',
    storageBucket: 'my-ai-pal-6e97a.firebasestorage.app',
    messagingSenderId: '344745789185',
    appId: '1:344745789185:web:cb6bb5590e7d9b5e797d00',
    measurementId: 'G-73F3M8MJSE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPzeLuTJUzvfQGIuR2IR2gKFGZLbEEYzw',
    appId: '1:344745789185:android:249445f9a056f4ad797d00',
    messagingSenderId: '344745789185',
    projectId: 'my-ai-pal-6e97a',
    storageBucket: 'my-ai-pal-6e97a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCToopi7ZDP2FUEFe76XmAT6DeN3JOXHZU',
    appId: '1:344745789185:ios:679f024f2f3c603a797d00',
    messagingSenderId: '344745789185',
    projectId: 'my-ai-pal-6e97a',
    storageBucket: 'my-ai-pal-6e97a.firebasestorage.app',
    iosBundleId: 'com.example.myAiPal',
  );
}
