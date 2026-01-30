import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../utils/interest_constants.dart';

class TopicSubscriptionService {
  static final TopicSubscriptionService _instance = TopicSubscriptionService._internal();

  factory TopicSubscriptionService() {
    return _instance;
  }

  TopicSubscriptionService._internal();

  FirebaseMessaging? _testMessaging;
  FirebaseMessaging get _messaging => _testMessaging ?? FirebaseMessaging.instance;

  @visibleForTesting
  set messaging(FirebaseMessaging messaging) => _testMessaging = messaging;

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Update region subscriptions
  Future<void> updateRegionSubscriptions(List<String> oldRegions, List<String> newRegions) async {
    final toUnsubscribe = oldRegions.where((r) => !newRegions.contains(r)).toList();
    final toSubscribe = newRegions.where((r) => !oldRegions.contains(r)).toList();

    for (final region in toUnsubscribe) {
      final topic = InterestConstants.regionToTopicMap[region] ??
                   InterestConstants.regionToTopicMap[region.toLowerCase()];
      if (topic != null) await unsubscribeFromTopic(topic);
    }

    for (final region in toSubscribe) {
      final topic = InterestConstants.regionToTopicMap[region] ??
                   InterestConstants.regionToTopicMap[region.toLowerCase()];
      if (topic != null) await subscribeToTopic(topic);
    }
  }

  /// Update interest subscriptions
  /// Note: input interests are Chinese names (e.g. '電影')
  Future<void> updateInterestSubscriptions(List<String> oldInterests, List<String> newInterests) async {
    final toUnsubscribe = oldInterests.where((i) => !newInterests.contains(i)).toList();
    final toSubscribe = newInterests.where((i) => !oldInterests.contains(i)).toList();

    for (final interest in toUnsubscribe) {
      final topicId = InterestConstants.getTopicForInterest(interest);
      if (topicId != null) {
        await unsubscribeFromTopic('interest_$topicId');
      }
    }

    for (final interest in toSubscribe) {
      final topicId = InterestConstants.getTopicForInterest(interest);
      if (topicId != null) {
        await subscribeToTopic('interest_$topicId');
      }
    }
  }
}
