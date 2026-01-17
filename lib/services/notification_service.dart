import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Initialize and request permission (if not already done)
  Future<void> initialize() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('FCM Token Refreshed: $token');
      // Token updates are handled by AuthProvider typically, or we can update here if we have UID
      // But we don't have easy access to UID here without auth instance
    });
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a specific topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Sync user subscriptions with FCM
  /// Call this when user data loads or changes
  Future<void> syncSubscriptions(UserModel user) async {
    // Current valid topics logic
    // We should ensure the user is subscribed to all topics in their list
    // And ideally unsubscribed from others, but we don't know "others" easily
    // without tracking local state.
    // However, for this task, we will just subscribe to what is in the list.

    // Also subscribe to 'all_users' by default if not present
    // await subscribeToTopic('all_users'); // Optional, depending on policy

    for (final topic in user.subscribedTopics) {
      await subscribeToTopic(topic);
    }

    // Note: We are not aggressively unsubscribing here because we don't know
    // what they were subscribed to before without keeping local state or
    // relying on the previous user model state passed in.
    // A better approach in UI is: when user unchecks, call unsubscribe.
  }

  /// Helper to get topic name for a region
  static String getRegionTopic(String region) {
    // Normalize region string, e.g. "Taipei" -> "region_taipei"
    return 'region_${region.toLowerCase()}';
  }

  /// Helper to get topic name for an interest
  static String getInterestTopic(String interest) {
    // e.g. "Sports" -> "interest_sports"
    return 'interest_${interest.toLowerCase()}';
  }
}
