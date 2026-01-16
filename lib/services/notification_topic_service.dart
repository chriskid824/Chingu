import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class NotificationTopicService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // City to Topic Mapping
  static const Map<String, String> _cityToTopicMap = {
    '台北市': 'region_taipei',
    '新北市': 'region_new_taipei',
    '桃園市': 'region_taoyuan',
    '台中市': 'region_taichung',
    '台南市': 'region_tainan',
    '高雄市': 'region_kaohsiung',
  };

  // Interest to Topic Mapping
  static const Map<String, String> _interestToTopicMap = {
    '電影': 'interest_movie',
    '音樂': 'interest_music',
    '遊戲': 'interest_game',
    '閱讀': 'interest_reading',
    '動漫': 'interest_anime',
    '桌遊': 'interest_board_game',
    '美食': 'interest_food',
    '旅遊': 'interest_travel',
    '咖啡': 'interest_coffee',
    '寵物': 'interest_pet',
    '烹飪': 'interest_cooking',
    '品酒': 'interest_wine',
    '購物': 'interest_shopping',
    '籃球': 'interest_basketball',
    '健身': 'interest_fitness',
    '跑步': 'interest_running',
    '游泳': 'interest_swimming',
    '瑜珈': 'interest_yoga',
    '爬山': 'interest_hiking',
    '羽球': 'interest_badminton',
    '攝影': 'interest_photography',
    '繪畫': 'interest_painting',
    '設計': 'interest_design',
    '手作': 'interest_diy',
    '寫作': 'interest_writing',
    '科技': 'interest_tech',
    '程式設計': 'interest_coding',
    '投資理財': 'interest_finance',
    '語言學習': 'interest_language',
  };

  /// Syncs the user's topic subscriptions based on their profile and preferences.
  ///
  /// [oldUser]: The previous state of the user (null if initial load).
  /// [newUser]: The new state of the user.
  /// [enableMarketing]: Whether marketing notifications (topics) are enabled.
  Future<void> syncTopics(UserModel? oldUser, UserModel newUser, {bool enableMarketing = true}) async {
    if (!enableMarketing) {
      // If marketing is disabled, unsubscribe from everything we might have subscribed to.
      // Since we don't track state locally, we use the newUser's potential topics to unsubscribe.
      // Or if we have oldUser, use that.
      // Safest is to unsubscribe from newUser's topics (as that's what we would be subscribed to).
      await _unsubscribeFromUserTopics(newUser);
      return;
    }

    // 1. Region Subscription
    String? newRegionTopic = _cityToTopicMap[newUser.city];
    String? oldRegionTopic = oldUser != null ? _cityToTopicMap[oldUser.city] : null;

    if (newRegionTopic != oldRegionTopic) {
      if (oldRegionTopic != null) {
        await _unsubscribe(oldRegionTopic);
      }
      if (newRegionTopic != null) {
        await _subscribe(newRegionTopic);
      }
    } else if (newRegionTopic != null && oldUser == null) {
      // Initial load, ensure subscribed
      await _subscribe(newRegionTopic);
    }

    // 2. Interests Subscription
    Set<String> newInterests = newUser.interests.toSet();
    Set<String> oldInterests = oldUser?.interests.toSet() ?? {};

    // Find removed interests
    for (String interest in oldInterests) {
      if (!newInterests.contains(interest)) {
        String? topic = _interestToTopicMap[interest];
        if (topic != null) {
          await _unsubscribe(topic);
        }
      }
    }

    // Find added interests
    for (String interest in newInterests) {
      if (!oldInterests.contains(interest) || oldUser == null) {
        String? topic = _interestToTopicMap[interest];
        if (topic != null) {
          await _subscribe(topic);
        }
      }
    }
  }

  /// Unsubscribes from all topics relevant to the user.
  /// Used on logout or when disabling notifications.
  Future<void> clearSubscriptions(UserModel user) async {
    await _unsubscribeFromUserTopics(user);
  }

  Future<void> _unsubscribeFromUserTopics(UserModel user) async {
    // Region
    String? regionTopic = _cityToTopicMap[user.city];
    if (regionTopic != null) {
      await _unsubscribe(regionTopic);
    }

    // Interests
    for (String interest in user.interests) {
      String? topic = _interestToTopicMap[interest];
      if (topic != null) {
        await _unsubscribe(topic);
      }
    }
  }

  Future<void> _subscribe(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> _unsubscribe(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}
