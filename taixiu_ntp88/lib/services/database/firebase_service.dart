import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  
  static const String apiKey = "AIzaSyDkybz8HmV-kJF7nIWGlD37x8ZUpL8CO4M";
  static const String appId = "1:159588266332:web:fc2d2cc27ecaab8eda1199";
  
  static const String messagingSenderId = "159588266332";
  static const String projectId = "tai-xiu-ntp88";
  static const String authDomain = "tai-xiu-ntp88.firebaseapp.com";
  static const String storageBucket = "tai-xiu-ntp88.firebasestorage.app";

  static Future<void> init() async {
    try {
      if (kIsWeb) {
        if (apiKey == "YOUR_API_KEY" || appId == "YOUR_APP_ID") {
          throw Exception("Firebase Web Config (apiKey/appId) chưa được thiết lập.");
        }
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: messagingSenderId,
            projectId: projectId,
            authDomain: authDomain,
            storageBucket: storageBucket,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      _isInitialized = true;
      if (kDebugMode) {
        print("Firebase initialized successfully!");
      }
    } catch (e) {
      _isInitialized = false;
      if (kDebugMode) {
        print("Firebase initialization failed: $e");
        print("Macau Prestige will run in fallback MOCK mode for demo testing.");
      }
    }
  }
}
