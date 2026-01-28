import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class TopicSubscriptionService {
  static final TopicSubscriptionService _instance = TopicSubscriptionService._internal();

  factory TopicSubscriptionService() {
    return _instance;
  }

  TopicSubscriptionService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// 訂閱主題
  Future<void> subscribeToTopic(String topic) async {
    try {
      debugPrint('Subscribing to topic: $topic');
      await _fcm.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
      // 在生產環境中應該記錄到 Crashlytics
    }
  }

  /// 取消訂閱主題
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      debugPrint('Unsubscribing from topic: $topic');
      await _fcm.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}
