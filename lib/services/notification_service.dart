import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/routes/app_router.dart';

/// Top-level background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you need to access Firestore or other Firebase services here,
  // you might need to initialize Firebase.
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
  final FirestoreService _firestoreService = FirestoreService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final NotificationABService _abService = NotificationABService();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Handle message opened app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageOpenedApp(message);
    });

    _isInitialized = true;
  }

  /// Handle incoming foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }

    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    // Determine content using AB Service or fallback to message content
    String title = message.notification?.title ?? 'New Notification';
    String body = message.notification?.body ?? '';

    // Parse data for AB testing customization
    final data = message.data;
    final String? typeStr = data['type'];

    if (typeStr != null) {
      // Try to parse type
      NotificationType? type;
      try {
        type = NotificationType.values.firstWhere((e) => e.toString().split('.').last == typeStr);
      } catch (e) {
        // Unknown type
      }

      if (type != null) {
        final content = _abService.getContent(userId, type, params: data);
        // If we have valid content from AB service, prefer it (unless the message explicitly has a notification block which usually takes precedence in display, but for local display we can override)
        // However, if the message *already* has a notification block, standard FCM SDK behavior is to NOT trigger onMessage if the app is in background, but it DOES trigger if in foreground.
        // So we can override the display text here.
        title = content.title;
        body = content.body;
      }
    }

    if (body.isEmpty) return; // Don't show empty notifications

    // Construct NotificationModel
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: typeStr ?? 'system',
      title: title,
      message: body,
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? data['imageUrl'],
      actionType: data['actionType'], // e.g., 'open_chat', 'view_event'
      actionData: data['actionData'], // e.g., userId, eventId
      isRead: false,
      createdAt: DateTime.now(),
    );

    _richNotificationService.showNotification(notification);
  }

  /// Handle notification tap when app is opened from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message clicked!');
    final data = message.data;
    final actionType = data['actionType'];
    // final actionData = data['actionData'];

    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // Simple navigation logic matching RichNotificationService
    switch (actionType) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // Default to notifications screen or home
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Check and save token to Firestore
  Future<void> checkAndSaveToken(String userId) async {
    try {
      final String? token = await getToken();
      if (token == null) return;

      // Update token in Firestore
      // Note: We might want to check if the token has changed to save writes,
      // but Firestore sets are relatively cheap and it ensures consistency.
      // Also, we don't have local storage of the last sent token easily available without adding shared_preferences.
      // Assuming straightforward update for now.

      await _firestoreService.updateUser(userId, {
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM Token updated for user $userId');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _firestoreService.updateUser(userId, {
          'fcmToken': newToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        debugPrint('FCM Token refreshed and updated for user $userId');
      });

    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }
}
