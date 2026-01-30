import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/models/notification_preferences_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationManagerProvider extends ChangeNotifier {
  final NotificationStorageService _storage = NotificationStorageService();
  final RichNotificationService _richNotification = RichNotificationService();

  StreamSubscription? _subscription;
  String? _currentUserId;
  DateTime? _startTime;
  NotificationPreferences _currentPrefs = const NotificationPreferences();

  // Called when AuthProvider updates
  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated && auth.userModel != null) {
      final userId = auth.userModel!.uid;
      final prefs = auth.userModel!.notificationPreferences;

      _currentPrefs = prefs;

      // If user changed or not listening yet
      if (_currentUserId != userId || _subscription == null) {
        _startListening(userId);
      }
    } else {
      _stopListening();
    }
  }

  void _startListening(String userId) {
    _stopListening();
    _currentUserId = userId;
    _startTime = DateTime.now();

    _subscription = _storage.watchNotificationChanges(userId).listen((changes) {
      for (var change in changes) {
        // Only handle added notifications
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final notification = NotificationModel.fromMap(data, change.doc.id);
            _processNotification(notification);
          }
        }
      }
    });
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
  }

  void _processNotification(NotificationModel notification) {
    // 1. Check if notification is new (created after start time)
    if (_startTime != null && notification.createdAt.isBefore(_startTime!)) {
      return;
    }

    // 2. Check Push Enabled
    if (!_currentPrefs.pushEnabled) return;

    // 3. Check specific type preferences
    bool shouldShow = false;
    switch (notification.type) {
      case 'match':
        shouldShow = _currentPrefs.matchSuccess;
        break;
      case 'message':
        shouldShow = _currentPrefs.newMessage;
        break;
      case 'event':
        shouldShow = _currentPrefs.eventReminder || _currentPrefs.eventChange;
        break;
      case 'system':
        // If needed, check marketing flags here if system message is promotional
        shouldShow = true;
        break;
      default:
        shouldShow = true;
    }

    if (shouldShow) {
      // 4. Handle Preview
      NotificationModel displayNotification = notification;
      if (!_currentPrefs.showPreview && notification.type == 'message') {
        displayNotification = NotificationModel(
          id: notification.id,
          userId: notification.userId,
          type: notification.type,
          title: notification.title,
          message: '您有一則新訊息',
          imageUrl: null, // Hide image in preview
          actionType: notification.actionType,
          actionData: notification.actionData,
          isRead: notification.isRead,
          createdAt: notification.createdAt,
        );
      }

      _richNotification.showNotification(displayNotification);
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
