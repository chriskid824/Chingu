import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class TopicSubscriptionService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Region mapping: Chinese name -> Topic key
  static const Map<String, String> regionMapping = {
    '台北市': 'region_taipei',
    '台中市': 'region_taichung',
    '高雄市': 'region_kaohsiung',
  };

  // Interest mapping: Category/Interest name -> Topic key
  static const Map<String, String> interestMapping = {
    '電影': 'topic_movie',
    '音樂': 'topic_music',
    '遊戲': 'topic_gaming',
    '美食': 'topic_food',
    '旅遊': 'topic_travel',
    '運動': 'topic_sports',
    '科技': 'topic_tech',
    '藝術': 'topic_art',
    '閱讀': 'topic_reading',
    '寵物': 'topic_pets',
  };

  static List<String> get availableRegions => regionMapping.keys.toList();
  static List<String> get availableTopics => interestMapping.keys.toList();

  /// Updates the user's topic subscriptions in Firestore and FCM.
  Future<void> updateSubscriptions(
    String userId, {
    required List<String> newRegions,
    required List<String> newTopics,
  }) async {
    try {
      // 1. Fetch current user data to get old subscriptions
      final user = await _firestoreService.getUser(userId);
      if (user == null) {
        throw Exception('User not found');
      }

      final oldRegions = user.subscribedRegions;
      final oldTopics = user.subscribedTopics;

      // 2. Calculate diffs and update FCM for Regions
      await _processSubscriptionDiff(
        oldList: oldRegions,
        newList: newRegions,
        mapping: regionMapping,
      );

      // 3. Calculate diffs and update FCM for Topics
      await _processSubscriptionDiff(
        oldList: oldTopics,
        newList: newTopics,
        mapping: interestMapping,
      );

      // 4. Update Firestore
      await _firestoreService.updateUser(userId, {
        'subscribedRegions': newRegions,
        'subscribedTopics': newTopics,
      });

      debugPrint('Subscriptions updated successfully for user $userId');

    } catch (e) {
      debugPrint('Error updating subscriptions: $e');
      rethrow;
    }
  }

  /// Helper to handle subscribe/unsubscribe logic based on list difference
  Future<void> _processSubscriptionDiff({
    required List<String> oldList,
    required List<String> newList,
    required Map<String, String> mapping,
  }) async {
    final oldSet = oldList.toSet();
    final newSet = newList.toSet();

    // To unsubscribe: present in old but not in new
    final toUnsubscribe = oldSet.difference(newSet);

    // To subscribe: present in new but not in old
    final toSubscribe = newSet.difference(oldSet);

    for (final item in toUnsubscribe) {
      final topic = mapping[item];
      if (topic != null) {
        try {
          await _firebaseMessaging.unsubscribeFromTopic(topic);
          debugPrint('Unsubscribed from topic: $topic');
        } catch (e) {
          debugPrint('Failed to unsubscribe from $topic: $e');
        }
      }
    }

    for (final item in toSubscribe) {
      final topic = mapping[item];
      if (topic != null) {
        try {
          await _firebaseMessaging.subscribeToTopic(topic);
          debugPrint('Subscribed to topic: $topic');
        } catch (e) {
          debugPrint('Failed to subscribe to $topic: $e');
        }
      }
    }
  }
}
