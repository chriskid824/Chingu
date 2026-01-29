import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_ab_service.dart';
import 'notification_storage_service.dart';
import 'rich_notification_service.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationABService _abService = NotificationABService();
  final RichNotificationService _richNotificationService = RichNotificationService();
  final NotificationStorageService _storageService = NotificationStorageService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 設定點擊監聽器
    _richNotificationService.onNotificationClick = _handleNotificationClick;

    // 初始化 RichNotificationService
    await _richNotificationService.initialize();

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// 發送通知 (包含 A/B 測試內容選擇、儲存、發送和追蹤)
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    Map<String, dynamic>? params,
    String? imageUrl,
    String? actionType,
    String? actionData,
  }) async {
    try {
      // 1. A/B 測試決定內容
      final group = _abService.getGroup(userId);
      final content = _abService.getContent(userId, type, params: params);

      // 2. 創建 NotificationModel (暫時沒有 ID)
      final tempModel = NotificationModel(
        id: '', // 將由 StorageService 生成
        userId: userId,
        type: type.toString().split('.').last, // e.g., 'match'
        title: content.title,
        message: content.body,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        isRead: false,
        createdAt: DateTime.now(),
      );

      // 3. 儲存到 Firestore 並獲取 ID
      final notificationId = await _storageService.saveNotification(tempModel);

      // 更新 ID
      final notificationModel = NotificationModel(
        id: notificationId,
        userId: userId,
        type: tempModel.type,
        title: tempModel.title,
        message: tempModel.message,
        imageUrl: tempModel.imageUrl,
        actionType: tempModel.actionType,
        actionData: tempModel.actionData,
        isRead: tempModel.isRead,
        createdAt: tempModel.createdAt,
      );

      // 4. 追蹤發送事件
      await _recordStat(
        userId: userId,
        notificationId: notificationId,
        type: notificationModel.type,
        event: 'send',
        group: group.toString().split('.').last, // 'control' or 'variant'
      );

      // 5. 顯示本地通知
      await _richNotificationService.showNotification(
        notificationModel,
        extraPayload: {
          'group': group.toString().split('.').last,
          'userId': userId,
        },
      );
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// 處理通知點擊追蹤
  void _handleNotificationClick(Map<String, dynamic> payload) {
    try {
      final String? notificationId = payload['notificationId'];
      final String? userId = payload['userId'];
      final String? group = payload['group'];
      // type 可能不在 payload 中，如果需要可以加入，或者從 Firestore 查
      // 這裡我們盡量記錄有的資訊

      if (notificationId != null) {
         _recordStat(
          userId: userId ?? 'unknown',
          notificationId: notificationId,
          type: 'unknown', // 點擊時可能無法立即得知 type，除非也在 payload
          event: 'click',
          group: group ?? 'unknown',
        );
      }
    } catch (e) {
      debugPrint('Error handling notification click: $e');
    }
  }

  /// 記錄統計數據
  Future<void> _recordStat({
    required String userId,
    required String notificationId,
    required String type,
    required String event, // 'send' or 'click'
    required String group,
  }) async {
    try {
      await _firestore.collection('notification_stats').add({
        'userId': userId,
        'notificationId': notificationId,
        'notificationType': type,
        'event': event,
        'group': group,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording notification stat: $e');
    }
  }
}
