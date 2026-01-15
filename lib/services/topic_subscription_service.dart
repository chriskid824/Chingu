import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

class TopicSubscriptionService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Singleton
  static final TopicSubscriptionService _instance = TopicSubscriptionService._internal();
  factory TopicSubscriptionService() => _instance;
  TopicSubscriptionService._internal();

  /// Subscribe or unsubscribe from a region
  Future<void> updateRegionSubscription(String userId, String region, bool isSubscribed) async {
    // Topic names must be regex [a-zA-Z0-9-_.~%]+
    // Region strings (taipei, taichung) should be safe, but let's lowercase and check
    final topic = 'region_${region.toLowerCase()}';

    if (isSubscribed) {
      await _fcm.subscribeToTopic(topic);
    } else {
      await _fcm.unsubscribeFromTopic(topic);
    }

    // Update Firestore
    final updateData = {
      'subscribedRegions': isSubscribed
          ? FieldValue.arrayUnion([region])
          : FieldValue.arrayRemove([region])
    };

    await _firestoreService.updateUser(userId, updateData);
  }

  /// Subscribe or unsubscribe from an interest
  Future<void> updateInterestSubscription(String userId, String interest, bool isSubscribed) async {
    // Encode interest to be topic-safe
    // Uri.encodeComponent converts special chars to %XX which is allowed in FCM topics
    final encodedInterest = Uri.encodeComponent(interest);
    final topic = 'interest_$encodedInterest';

    if (isSubscribed) {
      await _fcm.subscribeToTopic(topic);
    } else {
      await _fcm.unsubscribeFromTopic(topic);
    }

    final updateData = {
      'subscribedInterests': isSubscribed
          ? FieldValue.arrayUnion([interest])
          : FieldValue.arrayRemove([interest])
    };

    await _firestoreService.updateUser(userId, updateData);
  }

  /// Sync device subscriptions with user profile
  /// Call this on login or app start to ensure device is subscribed to user's topics
  Future<void> syncSubscriptions(UserModel user) async {
    for (final region in user.subscribedRegions) {
       await _fcm.subscribeToTopic('region_${region.toLowerCase()}');
    }

    for (final interest in user.subscribedInterests) {
       final encodedInterest = Uri.encodeComponent(interest);
       await _fcm.subscribeToTopic('interest_$encodedInterest');
    }
  }
}
