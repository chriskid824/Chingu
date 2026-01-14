import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

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

  /// 更新訂閱列表
  ///
  /// [oldTopics] 舊的訂閱列表
  /// [newTopics] 新的訂閱列表
  Future<void> updateSubscriptions(List<String> oldTopics, List<String> newTopics) async {
    // 找出需要取消訂閱的主題 (在舊列表中但不在新列表中)
    final topicsToUnsubscribe = oldTopics.where((t) => !newTopics.contains(t)).toList();

    // 找出需要訂閱的主題 (在新列表中但不在舊列表中)
    final topicsToSubscribe = newTopics.where((t) => !oldTopics.contains(t)).toList();

    for (final topic in topicsToUnsubscribe) {
      await unsubscribeFromTopic(topic);
    }

    for (final topic in topicsToSubscribe) {
      await subscribeToTopic(topic);
    }
  }
}
