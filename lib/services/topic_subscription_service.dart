import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../core/constants/notification_topics.dart';
import 'firestore_service.dart';

class TopicSubscriptionService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Update region subscription
  ///
  /// [userId] The user's ID
  /// [region] The region name (e.g., 'Taipei')
  /// [isSubscribed] Whether to subscribe or unsubscribe
  Future<void> updateRegionSubscription({
    required String userId,
    required String region,
    required bool isSubscribed,
  }) async {
    final topicId = NotificationTopics.getRegionTopicId(region);

    try {
      if (isSubscribed) {
        await _firebaseMessaging.subscribeToTopic(topicId);
        // Use FirestoreService's update which uses set with merge,
        // but for array operations we need direct update or specific handling.
        // Since FirestoreService.updateUser takes a Map, we can pass FieldValue.
        await _firestoreService.updateUser(userId, {
          'subscribedRegions': FieldValue.arrayUnion([region])
        });
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topicId);
        await _firestoreService.updateUser(userId, {
          'subscribedRegions': FieldValue.arrayRemove([region])
        });
      }
    } catch (e) {
      throw Exception('Failed to update region subscription: $e');
    }
  }

  /// Update topic/interest subscription
  ///
  /// [userId] The user's ID
  /// [topic] The topic name (e.g., 'Food')
  /// [isSubscribed] Whether to subscribe or unsubscribe
  Future<void> updateTopicSubscription({
    required String userId,
    required String topic,
    required bool isSubscribed,
  }) async {
    final topicId = NotificationTopics.getInterestTopicId(topic);

    try {
      if (isSubscribed) {
        await _firebaseMessaging.subscribeToTopic(topicId);
        await _firestoreService.updateUser(userId, {
          'subscribedTopics': FieldValue.arrayUnion([topic])
        });
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topicId);
        await _firestoreService.updateUser(userId, {
          'subscribedTopics': FieldValue.arrayRemove([topic])
        });
      }
    } catch (e) {
      throw Exception('Failed to update topic subscription: $e');
    }
  }

  /// Batch subscribe to initial topics (e.g., on login or restore)
  /// This is useful if we want to ensure device is synced with backend
  Future<void> syncSubscriptions(List<String> regions, List<String> topics) async {
    for (final region in regions) {
      await _firebaseMessaging.subscribeToTopic(
        NotificationTopics.getRegionTopicId(region)
      );
    }
    for (final topic in topics) {
      await _firebaseMessaging.subscribeToTopic(
        NotificationTopics.getInterestTopicId(topic)
      );
    }
  }
}
