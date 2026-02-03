import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  AuthProvider? _authProvider;

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    notifyListeners();
  }

  List<String> get subscribedTopics => _authProvider?.userModel?.fcmTopics ?? [];

  bool isSubscribed(String topic) {
    return subscribedTopics.contains(topic);
  }

  bool isRegionSubscribed(String region) {
    return isSubscribed('region_$region');
  }

  bool isInterestSubscribed(String interest) {
    return isSubscribed('interest_${Uri.encodeComponent(interest)}');
  }

  Future<void> toggleRegionSubscription(String region, bool subscribe) async {
    final topic = 'region_$region';
    await _toggleTopic(topic, subscribe);
  }

  Future<void> toggleInterestSubscription(String interest, bool subscribe) async {
    final topic = 'interest_${Uri.encodeComponent(interest)}';
    await _toggleTopic(topic, subscribe);
  }

  Future<void> _toggleTopic(String topic, bool subscribe) async {
    final user = _authProvider?.userModel;
    if (user == null) return;

    try {
      if (subscribe) {
        await _firebaseMessaging.subscribeToTopic(topic);
        if (!user.fcmTopics.contains(topic)) {
          final newTopics = List<String>.from(user.fcmTopics)..add(topic);
           await _firestoreService.updateUser(user.uid, {'fcmTopics': newTopics});
        }
      } else {
        await _firebaseMessaging.unsubscribeFromTopic(topic);
        if (user.fcmTopics.contains(topic)) {
          final newTopics = List<String>.from(user.fcmTopics)..remove(topic);
          await _firestoreService.updateUser(user.uid, {'fcmTopics': newTopics});
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling topic $topic: $e');
      rethrow;
    }
  }
}
