import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // Replace these with your actual Firebase project settings from the Firebase Console
  // Go to: Project Settings -> General -> Your Apps -> Select/Create a Web app -> Copy Config
  static const String apiKey = 'AIzaSyC64LgQHqVPsRBqRD-6L_s5kaV-zWse-L0';
  static const String appId = '1:246316625668:web:ab49957d1dc66be899aa51';
  static const String messagingSenderId = '246316625668';
  static const String projectId = 'strawberrymobile-ea8a1';

  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
    );
  }
}
