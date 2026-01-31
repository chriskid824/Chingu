import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/notification_model.dart';

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp` before using other Firebase services.
  // await Firebase.initializeApp();

  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final RichNotificationService _richNotificationService = RichNotificationService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// Initialize Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize Local Notifications
    await _richNotificationService.initialize();

    // Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle Background Message Taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      // RichNotificationService handles navigation logic, we just need to ensure
      // the payload is processed. Since RichNotificationService logic is mostly inside
      // _onNotificationTap which is triggered by local notification tap,
      // we might need to manually trigger navigation here if the system handled the notification.
      // However, usually tapping a system notification (from FCM background) just opens the app.
      // If we want specific navigation, we need to handle it here.
      // For now, let's log it.
    });

    // Handle Initial Message (App Closed)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from notification: ${initialMessage.messageId}');
    }

    // Monitor Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      _onTokenRefresh(token);
    });

    _isInitialized = true;
  }

  /// Handle Token Refresh
  void _onTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await saveTokenToDatabase(user.uid, token: token);
    }
  }

  /// Get FCM Token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Save Token to Database
  Future<void> saveTokenToDatabase(String userId, {String? token}) async {
    try {
      final fcmToken = token ?? await getToken();
      if (fcmToken != null) {
        await _firestoreService.updateUser(userId, {
          'fcmToken': fcmToken,
          'lastTokenUpdate': DateTime.now(), // Optional: track when it was updated
        });
        debugPrint('FCM Token updated for user $userId');
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Show Local Notification from RemoteMessage
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      // Create NotificationModel
      // Note: `id` and `userId` are required.
      // userId is not critical for local display.
      final model = NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '', // Placeholder
        type: message.data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: android?.imageUrl ?? message.data['imageUrl'],
        actionType: message.data['actionType'],
        actionData: message.data['actionData'],
        createdAt: DateTime.now(),
      );

      _richNotificationService.showNotification(model);
    }
  }
}
