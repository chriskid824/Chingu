import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'analytics_service.dart';
import 'notification_ab_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final AnalyticsService _analytics = AnalyticsService();

  /// 追蹤通知發送事件
  ///
  /// 當通知被創建或顯示給用戶時調用
  Future<void> trackNotificationSent(NotificationModel notification) async {
    try {
      await _analytics.logEvent(
        name: 'notification_sent',
        parameters: {
          'notification_id': notification.id,
          'notification_type': notification.type,
          'experiment_group': notification.experimentGroup ?? 'unknown',
          'user_id': notification.userId,
        },
      );
      debugPrint('[NotificationService] Tracked sent: ${notification.id} (${notification.experimentGroup})');
    } catch (e) {
      debugPrint('[NotificationService] Error tracking notification sent: $e');
    }
  }

  /// 追蹤通知點擊事件
  ///
  /// 當用戶點擊通知時調用
  Future<void> trackNotificationClick(NotificationModel notification, {String? actionId}) async {
    try {
      await _analytics.logEvent(
        name: 'notification_clicked',
        parameters: {
          'notification_id': notification.id,
          'notification_type': notification.type,
          'experiment_group': notification.experimentGroup ?? 'unknown',
          'action_id': actionId ?? 'default',
          'user_id': notification.userId,
        },
      );
      debugPrint('[NotificationService] Tracked click: ${notification.id} (${notification.experimentGroup})');
    } catch (e) {
      debugPrint('[NotificationService] Error tracking notification click: $e');
    }
  }

  /// 輔助方法：獲取實驗組別名稱
  String getExperimentGroupName(ExperimentGroup group) {
    switch (group) {
      case ExperimentGroup.variant:
        return 'variant';
      case ExperimentGroup.control:
        return 'control';
    }
  }
}
