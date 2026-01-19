import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Mapping for Regions
  static const Map<String, String> regionTopics = {
    'Taipei': 'region_taipei',
    'Taichung': 'region_taichung',
    'Kaohsiung': 'region_kaohsiung',
    '台北': 'region_taipei',
    '台中': 'region_taichung',
    '高雄': 'region_kaohsiung',
    '台北市': 'region_taipei',
    '台中市': 'region_taichung',
    '高雄市': 'region_kaohsiung',
    '新北市': 'region_taipei', // Assuming New Taipei maps to Taipei topic for now, or add region_new_taipei
    '台南市': 'region_tainan',
  };

  // Mapping for Interests
  static const Map<String, String> interestTopics = {
    '電影': 'interest_movie',
    '音樂': 'interest_music',
    '遊戲': 'interest_gaming',
    '閱讀': 'interest_reading',
    '動漫': 'interest_anime',
    '桌遊': 'interest_boardgames',
    '美食': 'interest_food',
    '旅遊': 'interest_travel',
    '咖啡': 'interest_coffee',
    '寵物': 'interest_pets',
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
    '手作': 'interest_crafts',
    '寫作': 'interest_writing',
    '科技': 'interest_tech',
    '程式設計': 'interest_coding',
    '投資理財': 'interest_investing',
    '語言學習': 'interest_languages',
  };

  Future<void> initialize() async {
    // Request permission if not already granted
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Update user subscriptions based on new settings
  Future<void> updateUserSubscriptions({
    required String uid,
    required String? newRegion,
    required List<String> newInterests,
  }) async {
    try {
      // 1. Get old settings from Firestore to know what to unsubscribe
      final oldSettings = await _firestoreService.getNotificationSettings(uid);

      String? oldRegion = oldSettings?['region'];
      List<String> oldInterests = List<String>.from(oldSettings?['interests'] ?? []);

      // 2. Sync Region
      if (oldRegion != newRegion) {
        // Unsubscribe from old region
        if (oldRegion != null && regionTopics.containsKey(oldRegion)) {
          await _unsubscribeFromTopic(regionTopics[oldRegion]!);
        }
        // Subscribe to new region
        if (newRegion != null && regionTopics.containsKey(newRegion)) {
          await _subscribeToTopic(regionTopics[newRegion]!);
        }
      }

      // 3. Sync Interests
      // Calculate added and removed interests
      final addedInterests = newInterests.where((i) => !oldInterests.contains(i)).toList();
      final removedInterests = oldInterests.where((i) => !newInterests.contains(i)).toList();

      for (var interest in removedInterests) {
          String? topic = _getInterestTopic(interest);
          if (topic != null) {
              await _unsubscribeFromTopic(topic);
          }
      }

      for (var interest in addedInterests) {
          String? topic = _getInterestTopic(interest);
          if (topic != null) {
              await _subscribeToTopic(topic);
          }
      }

      // 4. Save new settings to Firestore
      await _firestoreService.updateNotificationSettings(uid, {
        'region': newRegion,
        'interests': newInterests,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('Notification subscriptions updated successfully');
    } catch (e) {
      print('Error updating user subscriptions: $e');
      rethrow;
    }
  }

  String? _getInterestTopic(String interestName) {
    if (interestTopics.containsKey(interestName)) {
      return interestTopics[interestName];
    }
    return null;
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to $topic');
    } catch (e) {
      print('Error subscribing to $topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from $topic');
    } catch (e) {
      print('Error unsubscribing from $topic: $e');
    }
  }
}
