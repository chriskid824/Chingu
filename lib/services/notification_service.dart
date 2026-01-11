import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize() async {
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
  }

  /// 更新用戶 FCM Token
  Future<void> updateFcmToken(String userId) async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token updated: $token');
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// 訂閱主題
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// 取消訂閱主題
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// 同步主題訂閱
  Future<void> syncTopics(List<String> newTopics, List<String> oldTopics) async {
    // Find topics to subscribe (in new but not in old)
    final topicsToSubscribe = newTopics.where((t) => !oldTopics.contains(t)).toList();

    // Find topics to unsubscribe (in old but not in new)
    final topicsToUnsubscribe = oldTopics.where((t) => !newTopics.contains(t)).toList();

    for (final topic in topicsToSubscribe) {
      await subscribeToTopic(topic);
    }

    for (final topic in topicsToUnsubscribe) {
      await unsubscribeFromTopic(topic);
    }
  }
}
