import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Dependencies
  FirebaseMessaging? _messagingInstance;
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseMessaging get _messaging => _messagingInstance ??= FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 請求通知權限
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // 前景訊息處理
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 背景應用開啟處理
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 設置點擊回調 (RichNotificationService 需要相應更新)
      _richNotificationService.onNotificationClick = _handleLocalNotificationClick;

      _isInitialized = true;
    }
  }

  /// 處理前景訊息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final data = message.data;
    final String type = data['type'] ?? 'system';

    // 準備 A/B 測試參數
    final Map<String, dynamic> params = Map<String, dynamic>.from(data);

    // 獲取通知類型和內容
    NotificationType notificationType = _getNotificationType(type);
    final content = _abService.getContent(userId, notificationType, params: params);

    // 獲取實驗組別
    final group = _abService.getGroup(userId);
    final variant = group == ExperimentGroup.control ? 'control' : 'variant';

    // 建立 NotificationModel
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      type: type,
      title: content.title,
      message: content.body,
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );

    // 顯示通知
    await _richNotificationService.showNotification(notification);

    // 追蹤發送 (Impression)
    await trackNotificationSend(notification.id, type, variant);
  }

  /// 處理背景訊息開啟
  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty) {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final group = _abService.getGroup(userId);
        final variant = group == ExperimentGroup.control ? 'control' : 'variant';
        trackNotificationClick(message.messageId ?? 'unknown', data['type'] ?? 'unknown', variant);
      }
    }
  }

  /// 處理本地通知點擊回調
  void _handleLocalNotificationClick(String notificationId, String? actionType, String? actionData, String? type) {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      final group = _abService.getGroup(userId);
      final variant = group == ExperimentGroup.control ? 'control' : 'variant';

      trackNotificationClick(notificationId, type ?? actionType ?? 'unknown', variant);
    }
  }

  NotificationType _getNotificationType(String type) {
    switch (type) {
      case 'match': return NotificationType.match;
      case 'message': return NotificationType.message;
      case 'event': return NotificationType.event;
      case 'rating': return NotificationType.rating;
      default: return NotificationType.system;
    }
  }

  /// 追蹤通知發送 (Impression)
  Future<void> trackNotificationSend(String notificationId, String type, String variant) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('notification_stats').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type,
        'variant': variant,
        'action': 'sent',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking notification send: $e');
    }
  }

  /// 追蹤通知點擊
  Future<void> trackNotificationClick(String notificationId, String type, String variant) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('notification_stats').add({
        'userId': userId,
        'notificationId': notificationId,
        'type': type,
        'variant': variant,
        'action': 'clicked',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking notification click: $e');
    }
  }

  @visibleForTesting
  void setDependencies({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    if (messaging != null) _messagingInstance = messaging;
    if (firestore != null) _firestoreInstance = firestore;
    if (auth != null) _authInstance = auth;
  }
}
