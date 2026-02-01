import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  FirebaseMessaging? _firebaseMessagingOverride;
  FirebaseMessaging get _firebaseMessaging => _firebaseMessagingOverride ?? FirebaseMessaging.instance;

  static const String _prefsKeySubscribedTopics = 'subscribed_topics';

  @visibleForTesting
  void setFirebaseMessagingForTesting(FirebaseMessaging messaging) {
    _firebaseMessagingOverride = messaging;
  }

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
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

    // Handle foreground messages if needed
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Here we could trigger RichNotificationService to show it
        // But for now, let's focus on subscription logic as requested.
      }
    });
  }

  /// Subscribe user to topics based on region and interests
  Future<void> subscribeToTopics(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> oldTopics = prefs.getStringList(_prefsKeySubscribedTopics) ?? [];
      final Set<String> oldTopicsSet = oldTopics.toSet();

      final Set<String> newTopics = {};

      // 1. Region Subscription
      final String? regionTopic = _getRegionTopic(user.city);
      if (regionTopic != null) {
        newTopics.add(regionTopic);
      }

      // 2. Interest Subscription
      for (final interest in user.interests) {
        final String? interestTopic = _getInterestTopic(interest);
        if (interestTopic != null) {
          newTopics.add(interestTopic);
        }
      }

      // Calculate Diff
      final Set<String> toSubscribe = newTopics.difference(oldTopicsSet);
      final Set<String> toUnsubscribe = oldTopicsSet.difference(newTopics);

      // Execute Unsubscribe
      for (final topic in toUnsubscribe) {
        try {
          await _firebaseMessaging.unsubscribeFromTopic(topic);
          debugPrint('Unsubscribed from topic: $topic');
        } catch (e) {
          debugPrint('Error unsubscribing from $topic: $e');
        }
      }

      // Execute Subscribe
      for (final topic in toSubscribe) {
        try {
          await _firebaseMessaging.subscribeToTopic(topic);
          debugPrint('Subscribed to topic: $topic');
        } catch (e) {
          debugPrint('Error subscribing to $topic: $e');
        }
      }

      // Save new state
      await prefs.setStringList(_prefsKeySubscribedTopics, newTopics.toList());

    } catch (e) {
      debugPrint('Error updating topic subscriptions: $e');
    }
  }

  String? _getRegionTopic(String city) {
    final lowerCity = city.trim().toLowerCase();

    if (lowerCity.contains('taipei') || lowerCity.contains('台北')) {
      return 'topic_region_taipei';
    } else if (lowerCity.contains('taichung') || lowerCity.contains('台中')) {
      return 'topic_region_taichung';
    } else if (lowerCity.contains('kaohsiung') || lowerCity.contains('高雄')) {
      return 'topic_region_kaohsiung';
    }
    return null;
  }

  String? _getInterestTopic(String interest) {
    if (interest.trim().isEmpty) return null;
    // Replace spaces with underscore and remove special chars
    // Only allow alphanumeric, underscore, dot, dash, percent
    final slug = interest.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final validSlug = slug.replaceAll(RegExp(r'[^a-z0-9-_.~%]'), '');

    if (validSlug.isEmpty) return null;
    return 'topic_interest_$validSlug';
  }
}
