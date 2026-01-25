import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    _initTapListener();
  }

  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _initTapListener() {
    _richNotificationService.onNotificationTap.listen((payload) {
      _handleNotificationTap(payload);
    });
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> payload) async {
    final String? notificationId = payload['notificationId'];
    final String? experimentGroup = payload['experimentGroup'];
    final String? type = payload['notificationType'];
    final String? userId = payload['userId'];

    if (userId != null && type != null && experimentGroup != null) {
       await trackClick(userId, type, experimentGroup, notificationId ?? 'unknown');
    }
  }

  /// Track notification send event
  Future<void> trackSend(String userId, String type, String group) async {
    try {
      await _firestore.collection('notification_stats').add({
        'userId': userId,
        'type': 'send',
        'notificationType': type,
        'experimentGroup': group,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking notification send: $e');
    }
  }

  /// Track notification click event
  Future<void> trackClick(String userId, String type, String group, String notificationId) async {
    try {
      await _firestore.collection('notification_stats').add({
        'userId': userId,
        'type': 'click',
        'notificationType': type,
        'experimentGroup': group,
        'notificationId': notificationId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking notification click: $e');
    }
  }

  /// Send a notification with A/B testing content and tracking
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
      // 1. Get content from AB Service
      final content = _abService.getContent(userId, type, params: params);
      final group = _abService.getGroup(userId);

      // Convert enum to string for storage/tracking
      final typeString = type.toString().split('.').last;
      final groupString = group.toString().split('.').last;

      // 2. Track Send
      await trackSend(userId, typeString, groupString);

      // 3. Create NotificationModel
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        type: typeString,
        title: content.title,
        message: content.body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
        experimentGroup: groupString,
      );

      // 4. Show Notification (Local)
      await _richNotificationService.showNotification(
        notification,
        extraPayload: {
          'userId': userId,
          'notificationType': typeString,
          'experimentGroup': groupString,
        },
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
