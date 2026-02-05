import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationTopicService {
  static final NotificationTopicService _instance = NotificationTopicService._internal();

  factory NotificationTopicService() {
    return _instance;
  }

  NotificationTopicService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Update topic subscriptions based on old and new selections.
  ///
  /// [oldRegions] - The list of regions the user was subscribed to.
  /// [newRegions] - The list of regions the user wants to subscribe to.
  /// [oldInterests] - The list of interests the user was subscribed to.
  /// [newInterests] - The list of interests the user wants to subscribe to.
  Future<void> updateSubscriptions({
    required List<String> oldRegions,
    required List<String> newRegions,
    required List<String> oldInterests,
    required List<String> newInterests,
  }) async {
    try {
      // Handle Regions
      await _handleTopicUpdates(
        oldList: oldRegions,
        newList: newRegions,
        prefix: 'region_',
      );

      // Handle Interests
      await _handleTopicUpdates(
        oldList: oldInterests,
        newList: newInterests,
        prefix: 'interest_',
      );
    } catch (e) {
      debugPrint('Error updating topic subscriptions: $e');
      // In a real app, we might want to re-throw or handle this more gracefully
    }
  }

  Future<void> _handleTopicUpdates({
    required List<String> oldList,
    required List<String> newList,
    required String prefix,
  }) async {
    // Convert to Set for easier operations
    final oldSet = oldList.toSet();
    final newSet = newList.toSet();

    // Topics to subscribe to: present in new but not in old
    final toSubscribe = newSet.difference(oldSet);

    // Topics to unsubscribe from: present in old but not in new
    final toUnsubscribe = oldSet.difference(newSet);

    // Perform operations
    for (final item in toSubscribe) {
      final topic = '$prefix$item';
      await _subscribeToTopic(topic);
    }

    for (final item in toUnsubscribe) {
      final topic = '$prefix$item';
      await _unsubscribeFromTopic(topic);
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      debugPrint('Subscribing to topic: $topic');
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Failed to subscribe to $topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      debugPrint('Unsubscribing from topic: $topic');
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Failed to unsubscribe from $topic: $e');
    }
  }
}
