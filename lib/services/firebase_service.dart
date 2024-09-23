import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;

class FirebaseService {
  FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? fcmToken;
  String? apnsToken;

  FirebaseService() {
    _initialize();
  }

  void _initialize() {
    _setupFirebase();
  }

  void _setupFirebase() async {
    await Firebase.initializeApp();

    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Listen for token updates
      FirebaseMessaging.instance.onTokenRefresh.listen((String newToken) {
        fcmToken = _encryptToken(newToken);
        print('New FCM Token: $fcmToken');
        if (Platform.isIOS) {
          _retrieveAPNsToken();
        }
      });

      // Get the initial FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        fcmToken = _encryptToken(token);
        print("Encrypted FCM Token: $fcmToken");
      }

      // Attempt to get the APNs token
      if (Platform.isIOS) {
        _retrieveAPNsToken();
      }
    } else {
      print("User did not grant notification permissions");
    }
  }

  void _retrieveAPNsToken() async {
    try {
      apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        print("APNS Token: $apnsToken");
      } else {
        print("APNS Token is not available yet. Retrying...");
        // Retry after a delay
        Future.delayed(Duration(seconds: 5), _retrieveAPNsToken);
      }
    } catch (e) {
      print("Error retrieving APNS Token: $e");
      // Retry after a delay
      Future.delayed(Duration(seconds: 5), _retrieveAPNsToken);
    }
  }

  // Encryption function remains the same
  String _encryptToken(String token) {
    final key = encrypt.Key.fromUtf8('1234567890123456'); // 16-byte key
    final iv = encrypt.IV.fromLength(8); // 8-byte IV for Salsa20
    final encrypter = encrypt.Encrypter(encrypt.Salsa20(key));

    final encrypted = encrypter.encrypt(token, iv: iv);
    return encrypted.base64;
  }
}