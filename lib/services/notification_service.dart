import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Background message handler
/// Must be a top-level function and annotated with @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await requestPermission();

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_onMessage);

    // Message opened app handler
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // Token refresh handler
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // Check if the app was opened from a terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    _isInitialized = true;
  }

  /// Request notification permissions
  Future<NotificationSettings> requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');
    return settings;
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Update the token in Firestore for the given user
  Future<void> updateToken(String userId) async {
    try {
      String? token = await getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    await _firestoreService.updateUser(userId, {
      'fcmToken': token,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
    });
    debugPrint('FCM Token updated for user: $userId');
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String newToken) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _saveTokenToFirestore(user.uid, newToken);
    }
  }

  /// Handle foreground messages
  void _onMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');

    if (message.notification != null) {
      final user = FirebaseAuth.instance.currentUser;

      final notification = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user?.uid ?? '',
        type: message.data['type'] ?? 'general',
        title: message.notification?.title ?? '',
        message: message.notification?.body ?? '',
        createdAt: DateTime.now(),
        isRead: false,
        imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
      );

      _richNotificationService.showNotification(notification);
    }
  }

  /// Handle notification opened app
  void _onMessageOpenedApp(RemoteMessage message) {
    debugPrint('A new onMessageOpenedApp event was published!');
    final actionType = message.data['actionType'];
    final actionData = message.data['actionData'];

    _richNotificationService.handleNavigation(actionType, actionData, null);
  }
}
