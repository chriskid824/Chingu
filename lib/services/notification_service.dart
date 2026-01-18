import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/models/user_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background message handler - usually handled by top-level function,
    // but here we focus on foreground logic as per task scope.

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Parse notification
      final notification = _parseNotification(message, user.uid);
      if (notification == null) return;

      // Fetch user settings
      // Note: In a real app, we might want to cache this or use AuthProvider
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return;

      final userModel = UserModel.fromFirestore(userDoc);

      // Show notification using RichNotificationService with settings check
      await RichNotificationService().showNotification(
        notification,
        settings: userModel.notificationSettings
      );

    } catch (e) {
      debugPrint('Error handling foreground message: $e');
    }
  }

  NotificationModel? _parseNotification(RemoteMessage message, String userId) {
    try {
      final data = message.data;
      final notification = message.notification;

      // Prefer data payload, fallback to notification payload
      final String title = data['title'] ?? notification?.title ?? '新通知';
      final String body = data['body'] ?? notification?.body ?? '';
      final String type = data['type'] ?? 'system';
      final String? imageUrl = data['imageUrl'] ?? (notification?.android?.imageUrl);
      final String? actionType = data['actionType'];
      final String? actionData = data['actionData'];

      return NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        title: title,
        message: body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing notification: $e');
      return null;
    }
  }
}
