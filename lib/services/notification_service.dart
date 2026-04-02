import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final NotificationABService _abService = NotificationABService();
  final NotificationStorageService _storageService = NotificationStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sends a notification with A/B testing and tracking.
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    try {
      // 1. Get content based on A/B group
      final content = _abService.getContent(userId, type, params: params);
      final group = _abService.getGroup(userId);

      // 2. Create Notification Model
      final notification = NotificationModel(
        id: '', // Firestore will generate ID
        userId: userId,
        type: type.name, // Convert Enum to String
        title: content.title,
        message: content.body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // 3. Save to Storage (Sends to In-App Inbox)
      final notificationId = await _storageService.saveNotification(notification);

      // 4. Track Send
      await _trackEvent('send', userId, type, group, notificationId);

    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Tracks a click on a notification.
  Future<void> trackClick(String notificationId, String userId, String typeStr) async {
    try {
      final group = _abService.getGroup(userId);

      // Convert String type back to Enum
      final type = NotificationType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => NotificationType.system,
      );

      await _trackEvent('click', userId, type, group, notificationId);
    } catch (e) {
      debugPrint('Error tracking click: $e');
    }
  }

  /// Internal method to log events to Firestore.
  Future<void> _trackEvent(
    String event, // 'send' or 'click'
    String userId,
    NotificationType type,
    ExperimentGroup group,
    String notificationId,
  ) async {
    try {
      final date = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final groupName = group.name;
      final typeName = type.name;

      // Document ID: date_group_type
      // This aggregates stats per day, per group, per type.
      final docRef = _firestore
          .collection('notification_stats')
          .doc('${date}_${groupName}_${typeName}');

      await docRef.set({
        'date': date,
        'group': groupName,
        'type': typeName,
        '${event}_count': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
      debugPrint('Error logging notification stats: $e');
    }
  }
}
