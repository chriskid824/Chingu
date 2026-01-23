import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// Update subscriptions based on old and new topic lists
  Future<void> updateSubscriptions(List<String> oldTopics, List<String> newTopics) async {
    final oldSet = oldTopics.toSet();
    final newSet = newTopics.toSet();

    final toSubscribe = newSet.difference(oldSet);
    final toUnsubscribe = oldSet.difference(newSet);

    if (toSubscribe.isEmpty && toUnsubscribe.isEmpty) {
      return;
    }

    try {
      // Subscribe to new topics
      for (final topic in toSubscribe) {
        await _subscribeToTopic(topic);
      }

      // Unsubscribe from removed topics
      for (final topic in toUnsubscribe) {
        await _unsubscribeFromTopic(topic);
      }
    } catch (e) {
      debugPrint('Error updating subscriptions: $e');
      rethrow;
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}
