import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/notification_model.dart';

class MessagingService {
  static final MessagingService _instance = MessagingService._internal();

  factory MessagingService() {
    return _instance;
  }

  MessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 初始化 Messaging Service
  Future<void> initialize() async {
    // 處理前台通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');

        // 顯示本地通知
        RichNotificationService().showNotification(
          NotificationModel(
            id: message.messageId ?? DateTime.now().toString(),
            title: message.notification?.title ?? '新通知',
            message: message.notification?.body ?? '',
            timestamp: DateTime.now(),
            type: 'system', // 預設類型
            actionType: message.data['actionType'],
            actionData: message.data['actionData'],
            imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          ),
        );
      }
    });

    // 處理後台訊息點擊
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
       debugPrint('A new onMessageOpenedApp event was published!');
       // 這裡可以處理導航，但 RichNotificationService 已經處理了本地通知的點擊
       // 如果是直接點擊 FCM 通知（非本地），可能需要在這裡處理
    });
  }

  /// 訂閱主題
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// 取消訂閱主題
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// 產生區域主題名稱
  static String getRegionTopic(String region) {
    // region 應該是 taipei, taichung, kaohsiung
    return 'region_${region.toLowerCase()}';
  }

  /// 產生興趣主題名稱
  static String getInterestTopic(String interestId) {
    return 'interest_$interestId';
  }

  /// 同步訂閱
  Future<void> syncSubscriptions(List<String> topics) async {
    for (var topic in topics) {
      await subscribeToTopic(topic);
    }
  }
}
