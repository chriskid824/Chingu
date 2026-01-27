import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import 'rich_notification_service.dart';
import '../models/notification_model.dart';

// Top-level background handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();

  debugPrint("Handling a background message: ${message.messageId}");

  // Only handle data messages that need local display manually.
  // Notification messages are handled by system tray.
  if (message.notification == null) {
    // This is a data message.
    // Initialize RichNotificationService (new instance in this isolate)
    final richNotificationService = RichNotificationService();
    await richNotificationService.initialize();

    // Construct NotificationModel from data
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: '', // Not available in background isolate easily, and not needed for display
      type: message.data['type'] ?? 'system',
      title: message.data['title'] ?? 'Notification',
      message: message.data['body'] ?? '',
      imageUrl: message.data['imageUrl'],
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );

    await richNotificationService.showNotification(notification);
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String? _currentUserId;
  bool _isInitialized = false;

  /// Initialize the Notification Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Get initial token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      _saveToken(token);
    }

    // Monitor token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
        // Show local notification for foreground messages
        _showForegroundNotification(message);
      } else {
        // Handle data-only message in foreground
         _showForegroundNotification(message);
      }
    });

    // Handle background notification taps (App was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleMessageNavigation(message);
    });

    // Handle initial message (App was terminated)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App launched from terminated state by notification');
      _handleMessageNavigation(initialMessage);
    }

    _isInitialized = true;
  }

  /// Set the current user ID to manage token saving
  void setUserId(String? uid) {
    _currentUserId = uid;
    if (uid != null) {
      // Refresh/Save token for the new user
      _firebaseMessaging.getToken().then((token) {
        if (token != null) {
          _saveToken(token);
        }
      });
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveToken(String token) async {
    if (_currentUserId != null) {
      try {
        await _firestoreService.updateUser(_currentUserId!, {
          'fcmToken': token,
          'lastTokenUpdate': DateTime.now(), // Optional: track update time
        });
        debugPrint('FCM Token saved for user: $_currentUserId');
      } catch (e) {
        debugPrint('Error saving FCM token: $e');
      }
    } else {
      debugPrint('No user logged in, skipping token save.');
    }
  }

  /// Show notification using RichNotificationService
  void _showForegroundNotification(RemoteMessage message) {
    // Construct NotificationModel
    // Use notification payload if available, otherwise data payload
    final String title = message.notification?.title ?? message.data['title'] ?? 'Notification';
    final String body = message.notification?.body ?? message.data['body'] ?? '';
    final String? imageUrl = message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl ?? message.data['imageUrl'];

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().toString(),
      userId: _currentUserId ?? '',
      type: message.data['type'] ?? 'system',
      title: title,
      message: body,
      imageUrl: imageUrl,
      actionType: message.data['actionType'],
      actionData: message.data['actionData'],
      createdAt: DateTime.now(),
      isRead: false,
    );

    RichNotificationService().showNotification(notification);
  }

  /// Handle navigation from notification tap
  void _handleMessageNavigation(RemoteMessage message) {
    final String? actionType = message.data['actionType'];
    final String? actionData = message.data['actionData'];

    // Delegate to RichNotificationService
    RichNotificationService().handleNavigation(actionType, actionData, null);
  }
}
