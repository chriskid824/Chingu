import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final RichNotificationService _richNotificationService = RichNotificationService();
  final NotificationABService _abService = NotificationABService();
  StreamSubscription? _tapSubscription;

  /// Initialize the service and listen for notification taps
  Future<void> initialize() async {
    await _richNotificationService.initialize();

    _tapSubscription?.cancel();
    _tapSubscription = _richNotificationService.onNotificationTapStream.listen((data) {
      _handleNotificationTap(data);
    });
  }

  /// Handle tap events for analytics tracking
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (data.containsKey('ab_tracking')) {
      try {
        final trackingData = Map<String, dynamic>.from(data['ab_tracking'] as Map);
        final String userId = trackingData['userId'];
        final String typeStr = trackingData['type'];
        final String groupStr = trackingData['group'];

        // Convert strings back to enums
        final NotificationType type = NotificationType.values.firstWhere(
          (e) => e.name == typeStr,
          orElse: () => NotificationType.system,
        );

        final ExperimentGroup group = ExperimentGroup.values.firstWhere(
          (e) => e.name == groupStr,
          orElse: () => ExperimentGroup.control,
        );

        _abService.trackNotificationClicked(userId, type, group);
      } catch (e) {
        debugPrint('Error handling notification tap tracking: $e');
      }
    }
  }

  /// Send a notification with A/B testing support and tracking
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? actionType,
    String? actionData,
    String? imageUrl,
  }) async {
    // 1. Get content and A/B group
    final content = _abService.getContent(userId, type, params: params);
    final group = _abService.getGroup(userId);

    // 2. Create NotificationModel
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type.name,
      title: content.title,
      message: content.body,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      createdAt: DateTime.now(),
      isRead: false,
    );

    // 3. Prepare tracking payload
    final trackingPayload = {
      'userId': userId,
      'type': type.name,
      'group': group.name,
    };

    // 4. Show notification via RichNotificationService
    await _richNotificationService.showNotification(
      notification,
      extraPayload: {'ab_tracking': trackingPayload},
    );

    // 5. Track send event
    await _abService.trackNotificationSent(userId, type, group);
  }

  void dispose() {
    _tapSubscription?.cancel();
  }
}
