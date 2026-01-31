import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional permission');
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing notification service: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Syncs user subscriptions by comparing old and new lists of topics.
  /// [oldTopics] is the list of topics the user was previously subscribed to.
  /// [newTopics] is the list of topics the user should be subscribed to.
  Future<void> syncUserSubscriptions(List<String> oldTopics, List<String> newTopics) async {
    final Set<String> oldSet = oldTopics.toSet();
    final Set<String> newSet = newTopics.toSet();

    // Topics to unsubscribe from (present in old but not in new)
    final Set<String> toUnsubscribe = oldSet.difference(newSet);

    // Topics to subscribe to (present in new but not in old)
    final Set<String> toSubscribe = newSet.difference(oldSet);

    for (final topic in toUnsubscribe) {
      await unsubscribeFromTopic(topic);
    }

    for (final topic in toSubscribe) {
      await subscribeToTopic(topic);
    }
  }
}
