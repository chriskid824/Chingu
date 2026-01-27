import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize(String uid) async {
    if (_isInitialized) return;

    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');

        // Get token
        String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _saveTokenToDatabase(uid, token);
        }

        // Listen to token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token Refreshed: $newToken');
          _saveTokenToDatabase(uid, newToken);
        });

      } else {
        debugPrint('User declined or has not accepted permission');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _saveTokenToDatabase(String uid, String token) async {
    try {
      await _firestoreService.updateUser(uid, {'fcmToken': token});
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
