import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// 主題訂閱服務 - 處理 FCM 主題訂閱
class TopicSubscriptionService {
  static final TopicSubscriptionService _instance = TopicSubscriptionService._internal();

  factory TopicSubscriptionService() {
    return _instance;
  }

  TopicSubscriptionService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 訂閱主題
  ///
  /// [topic] 主題名稱 (需符合 FCM 格式: [a-zA-Z0-9-_.~%]+)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// 取消訂閱主題
  ///
  /// [topic] 主題名稱
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// 同步主題訂閱狀態
  ///
  /// 比較新舊主題列表，自動執行訂閱和取消訂閱
  /// [oldTopics] 舊的主題列表
  /// [newTopics] 新的主題列表
  Future<void> syncTopics(List<String> oldTopics, List<String> newTopics) async {
    final Set<String> oldSet = Set.from(oldTopics);
    final Set<String> newSet = Set.from(newTopics);

    // 需要取消訂閱的主題 (在舊列表中但不在新列表中)
    final toUnsubscribe = oldSet.difference(newSet);
    for (final topic in toUnsubscribe) {
      await unsubscribeFromTopic(topic);
    }

    // 需要訂閱的主題 (在新列表中但不在舊列表中)
    final toSubscribe = newSet.difference(oldSet);
    for (final topic in toSubscribe) {
      await subscribeToTopic(topic);
    }
  }

  /// 格式化地區主題
  static String formatLocationTopic(String city) {
    // 移除可能的不合法字符
    final safeCity = city.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return 'topic_location_$safeCity';
  }

  /// 格式化興趣主題
  static String formatInterestTopic(String interest) {
    return 'topic_interest_${Uri.encodeComponent(interest)}';
  }
}
