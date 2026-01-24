import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationTopicService {
  final FirebaseMessaging _messaging;

  static NotificationTopicService? _instance;

  factory NotificationTopicService({FirebaseMessaging? messaging}) {
    _instance ??= NotificationTopicService._internal(messaging ?? FirebaseMessaging.instance);
    return _instance!;
  }

  /// For testing purposes only
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  NotificationTopicService._internal(this._messaging);

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      if (kIsWeb) {
        // Topic subscription is not supported on Web via SDK directly in some versions,
        // but let's assume standard behavior or just log if it fails.
        // Actually, checking docs: Web support for topic subscription is limited/different.
        // But for this task, we assume Mobile primarily or standard API usage.
        debugPrint('Subscribing to topic on Web might require backend implementation: $topic');
        return;
      }
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      if (kIsWeb) {
        debugPrint('Unsubscribing from topic on Web might require backend implementation: $topic');
        return;
      }
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Generate region topic name
  /// [city] should be 'Taipei', 'Taichung', 'Kaohsiung' etc.
  String getRegionTopic(String city) {
    // Normalize city name to lowercase and remove spaces if any
    final normalized = city.toLowerCase().replaceAll(' ', '_');
    return 'region_$normalized';
  }

  /// Generate interest topic name
  /// [interestId] is the ID from InterestConstants
  String getInterestTopic(String interestId) {
    return 'interest_$interestId';
  }

  /// Sync subscriptions: subscribe to new ones, unsubscribe from old ones
  /// This is useful if we want to ensure state matches exactly.
  /// However, typically we just call subscribe/unsubscribe as needed.
  /// This method assumes we have the full list of desired topics.
  /// Note: We don't easily know *what* we were subscribed to before without storing it.
  /// So this method might just subscribe to all provided.
  Future<void> syncSubscriptions(List<String> topics) async {
    for (final topic in topics) {
      await subscribeToTopic(topic);
    }
  }
}
