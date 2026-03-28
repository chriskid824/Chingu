import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:flutter/foundation.dart';

/// Notification Service - Handles notification logic and tracking
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationABService _abService = NotificationABService();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Gets notification content based on A/B test group and tracks the send event.
  /// This should be called when a notification is about to be displayed.
  Future<NotificationContent> getAndTrackNotificationContent(
    String userId,
    NotificationType type, {
    Map<String, dynamic>? params,
  }) async {
    final content = _abService.getContent(userId, type, params: params);

    // Track the send event
    await trackNotificationSend(userId, type);

    return content;
  }

  /// Tracks a notification send event.
  Future<void> trackNotificationSend(String userId, NotificationType type) async {
    final group = _abService.getGroup(userId);
    await _updateStats(group, type, isClick: false);
  }

  /// Tracks a notification click event.
  Future<void> trackNotificationClick(String userId, NotificationType type) async {
    final group = _abService.getGroup(userId);
    await _updateStats(group, type, isClick: true);
  }

  /// Updates the statistics in Firestore.
  /// Aggregates by Date, Group, and Type.
  Future<void> _updateStats(
    ExperimentGroup group,
    NotificationType type, {
    required bool isClick,
  }) async {
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final groupStr = group.name; // 'control' or 'variant'
    final typeStr = type.name;

    final docId = "${dateStr}_${groupStr}_${typeStr}";
    final docRef = _firestore.collection('notification_stats').doc(docId);

    try {
      // Use set with merge to create document if it doesn't exist
      await docRef.set({
        'date': dateStr,
        'group': groupStr,
        'type': typeStr,
        'sendCount': FieldValue.increment(isClick ? 0 : 1),
        'clickCount': FieldValue.increment(isClick ? 1 : 0),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('Notification stat tracked: $docId (click: $isClick)');
      }
    } catch (e) {
      // Fail silently for stats to avoid disrupting user experience
      if (kDebugMode) {
        print("Error updating notification stats: $e");
      }
    }
  }
}
