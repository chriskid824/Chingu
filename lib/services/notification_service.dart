import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 初始化通知服務
  Future<void> initialize() async {
    // 請求權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 處理前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // 這裡可以調用 RichNotificationService 顯示通知
        // 但為了避免循環依賴，這裡暫時只打印 log，或者使用事件總線
      }
    });

    // 處理背景點擊開啟
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // 導航邏輯通常在 RichNotificationService 或 main.dart 處理
    });

    // 監聽 Token 刷新
    _messaging.onTokenRefresh.listen((String token) {
      debugPrint("New token: $token");
      _saveTokenToDatabase(token);
    });

    // 獲取並保存初始 Token
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  /// 保存 Token 到 Firestore
  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
  }

  /// 訂閱主題
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      await _updateUserSubscription(topic, isSubscribing: true);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
      rethrow;
    }
  }

  /// 取消訂閱主題
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      await _updateUserSubscription(topic, isSubscribing: false);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
      rethrow;
    }
  }

  /// 更新用戶 Firestore 訂閱紀錄
  Future<void> _updateUserSubscription(String topic, {required bool isSubscribing}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);

    if (isSubscribing) {
      await userRef.update({
        'subscribedTopics': FieldValue.arrayUnion([topic])
      });
    } else {
      await userRef.update({
        'subscribedTopics': FieldValue.arrayRemove([topic])
      });
    }
  }

  /// 批量更新訂閱 (用於初始化或恢復設定)
  Future<void> syncSubscriptions(List<String> topics) async {
    // 使用 Future.wait 並行處理以提升效能
    await Future.wait(
      topics.map((topic) => _messaging.subscribeToTopic(topic))
    );
  }
}
