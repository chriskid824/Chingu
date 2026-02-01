import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';
import 'firestore_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final NotificationStorageService _storageService = NotificationStorageService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      await _setupFCM();
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    _isInitialized = true;
  }

  Future<void> _setupFCM() async {
    // Get token
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateToken(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }

    // Refresh token listener
    _messaging.onTokenRefresh.listen(_updateToken);

    // Foreground message listener
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _updateToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _firestoreService.updateUser(user.uid, {'fcmToken': token});
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Construct NotificationModel
    // Use data payload if available, fallback to notification fields
    final data = message.data;
    final notification = message.notification;

    final title = data['title'] ?? notification?.title ?? 'Notification';
    final body = data['message'] ?? data['body'] ?? notification?.body ?? '';
    final type = data['type'] ?? 'system';

    final model = NotificationModel(
      id: '', // Storage service will assign ID
      userId: user.uid,
      type: type,
      title: title,
      message: body,
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      isRead: false,
      createdAt: DateTime.now(),
    );

    try {
      // Save to storage
      await _storageService.saveNotification(model);

      // Show local notification
      await _richNotificationService.showNotification(model);
    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }
}
