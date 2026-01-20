import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static NotificationService? _instance;

  factory NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    _instance ??= NotificationService._internal(
      messaging: messaging ?? FirebaseMessaging.instance,
      firestore: firestore ?? FirebaseFirestore.instance,
      auth: auth ?? FirebaseAuth.instance,
    );
    return _instance!;
  }

  NotificationService._internal({
    required FirebaseMessaging messaging,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _messaging = messaging,
        _firestore = firestore,
        _auth = auth;

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 請求權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }

      // 獲取並保存 Token
      await _checkAndSaveToken();

      // 監聽 Token 刷新
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);

      // 監聽登入狀態變化，以便在用戶登入時更新 Token
      _auth.authStateChanges().listen((user) {
        if (user != null) {
          _checkAndSaveToken();
        }
      });

    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
  }

  Future<void> _checkAndSaveToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('FCM Token saved for user ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token to Firestore: $e');
      }
    }
  }

  /// 獲取當前 Token (用於測試或手動獲取)
  Future<String?> getFcmToken() async {
    return await _messaging.getToken();
  }
}
