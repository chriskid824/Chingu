import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'in_app_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted notification permission');
      // 即使沒權限，我們仍繼續初始化監聽，因為在某些情況下可能已經有權限
    }

    // 監聽前景訊息
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground notification: ${message.messageId}');

      // 只有當訊息包含通知內容時才顯示 In-App Banner
      // 或是根據 data 判斷
      if (message.notification != null || message.data.isNotEmpty) {
        try {
          final notification = _convertToNotificationModel(message);
          InAppNotificationService().showNotification(notification);
        } catch (e) {
          debugPrint('Error showing in-app notification: $e');
        }
      }
    });

    _isInitialized = true;
  }

  /// 將 RemoteMessage 轉換為 NotificationModel
  NotificationModel _convertToNotificationModel(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    // 嘗試獲取目前使用者 ID，若無則為空
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    // 優先使用 data 中的imageUrl，其次是 notification 中的
    String? imageUrl = data['imageUrl'];
    if (imageUrl == null && notification != null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        imageUrl = notification.android?.imageUrl;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        imageUrl = notification.apple?.imageUrl;
      }
    }

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: currentUserId,
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '新通知',
      message: notification?.body ?? data['message'] ?? '',
      imageUrl: imageUrl,
      actionType: data['actionType'],
      actionData: data['actionData'], // JSON string
      createdAt: DateTime.now(), // 使用當前時間
      isRead: false,
    );
  }
}
