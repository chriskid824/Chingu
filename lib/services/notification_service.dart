import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

/// 核心通知服務
/// 負責整合 Firebase Cloud Messaging (FCM)
/// 包括初始化、Token 註冊與更新、Token 刷新處理
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get token
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _saveTokenToDatabase(token);
      }

      // Setup refresh listener
      setupTokenRefresh();
    }

    // Listen to auth state changes to save token when user logs in
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        getToken().then((token) {
          if (token != null) {
            _saveTokenToDatabase(token);
          }
        });
      }
    });

    _isInitialized = true;
  }

  /// 設置 Token 刷新監聽
  void setupTokenRefresh() {
    _firebaseMessaging.onTokenRefresh.listen((String newToken) {
      debugPrint("FCM Token Refreshed: $newToken");
      _saveTokenToDatabase(newToken);
    });
  }

  /// 將 Token 儲存到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {
          'fcmToken': token,
        });
        debugPrint("FCM Token saved to Firestore for user: ${user.uid}");
      } catch (e) {
        debugPrint("Error saving FCM Token to Firestore: $e");
      }
    } else {
      debugPrint("User not logged in, skipping FCM Token save.");
    }
  }

  /// 手動獲取 Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// 刪除 Token (登出時調用)
  Future<void> deleteToken() async {
     try {
       await _firebaseMessaging.deleteToken();

       User? user = _auth.currentUser;
       if (user != null) {
          await _firestoreService.updateUser(user.uid, {
            'fcmToken': null,
          });
       }
     } catch (e) {
       debugPrint("Error deleting FCM Token: $e");
     }
  }
}
