import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../core/routes/app_routes.dart';

class RichNotificationService {
  // Singleton pattern
  static final RichNotificationService _instance = RichNotificationService._internal();

  factory RichNotificationService() {
    return _instance;
  }

  RichNotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Android 初始化設定
    // 預設使用 app icon，需確保 drawable/mipmap 中有 @mipmap/ic_launcher
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 初始化設定
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 請求 Android 13+ 通知權限
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // 設置 Firebase Messaging 監聽
    await setupFirebaseMessaging();

    _isInitialized = true;
  }

  /// 設置 Firebase Messaging
  Future<void> setupFirebaseMessaging() async {
    // 處理 App 關閉狀態下被打開
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      handleNotificationData(initialMessage.data);
    }

    // 處理 App 背景狀態下被打開
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      handleNotificationData(message.data);
    });
  }

  /// 處理通知點擊事件 (本地通知)
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        // 合併 actionId 到 data
        if (actionId != null && actionId != 'default') {
          data['actionType'] = actionId;
        }

        handleNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯 (核心方法)
  void handleNotificationData(Map<String, dynamic> data) {
    final navigator = AppRoutes.navigatorKey.currentState;
    if (navigator == null) return;

    final routeInfo = getRouteInfo(data);

    if (routeInfo != null) {
      navigator.pushNamed(
        routeInfo.routeName,
        arguments: routeInfo.arguments,
      );
    } else {
      // 默認導航
      navigator.pushNamed(AppRoutes.notifications);
    }
  }

  /// 獲取路由資訊 (便於測試)
  RouteInfo? getRouteInfo(Map<String, dynamic> data) {
    final String? notificationType = data['notification_type'] ?? data['type'];
    final String? actionType = data['actionType'];

    // 1. 優先處理: Match Success / New Message -> Chat Detail
    if (notificationType == 'match_success') {
      final chatRoomId = data['chatRoomId'] ?? data['matchId'];
      final otherUserId = data['matchedUserId'] ?? data['otherUserId'];

      if (chatRoomId != null && otherUserId != null) {
        return RouteInfo(
          AppRoutes.chatDetail,
          {
            'chatRoomId': chatRoomId,
            'otherUserId': otherUserId,
          },
        );
      }
    }

    if (notificationType == 'new_message') {
      final chatRoomId = data['chatRoomId'] ?? data['chatId'];
      final senderId = data['senderId'];

      if (chatRoomId != null && senderId != null) {
        return RouteInfo(
          AppRoutes.chatDetail,
          {
            'chatRoomId': chatRoomId,
            'otherUserId': senderId,
          },
        );
      }
    }

    // 2. 處理: Event -> Event Details
    if (notificationType == 'dinner_event' || notificationType == 'event_reminder' || actionType == 'view_event') {
      final eventId = data['eventId'] ?? data['actionData'];
      return RouteInfo(
        AppRoutes.eventDetail,
        eventId != null ? {'eventId': eventId} : null,
      );
    }

    // 3. 處理舊版 ActionType
    if (actionType != null) {
      switch (actionType) {
        case 'open_chat':
          return RouteInfo(AppRoutes.chatList);
        case 'match_history':
          return RouteInfo(AppRoutes.matchesList);
        default:
          return RouteInfo(AppRoutes.notifications);
      }
    }

    return null;
  }

  /// 顯示豐富通知
  Future<void> showNotification(NotificationModel notification) async {
    // Android 通知詳情
    StyleInformation? styleInformation;

    // 如果有圖片，下載並設置 BigPictureStyle
    if (notification.imageUrl != null && notification.imageUrl!.isNotEmpty) {
      try {
        final file = await DefaultCacheManager().getSingleFile(notification.imageUrl!);
        final ByteArrayAndroidBitmap bigPicture = ByteArrayAndroidBitmap(await file.readAsBytes());

        styleInformation = BigPictureStyleInformation(
          bigPicture,
          contentTitle: notification.title,
          summaryText: notification.message,
          hideExpandedLargeIcon: true,
        );
      } catch (e) {
        debugPrint('Error downloading image for notification: $e');
        // 圖片下載失敗則降級為普通通知
        styleInformation = BigTextStyleInformation(notification.message);
      }
    } else {
      styleInformation = BigTextStyleInformation(notification.message);
    }

    // 定義操作按鈕
    List<AndroidNotificationAction> actions = [];
    if (notification.actionType == 'open_chat') {
      actions.add(const AndroidNotificationAction(
        'open_chat',
        '回覆',
        showsUserInterface: true,
      ));
    } else if (notification.actionType == 'view_event') {
      actions.add(const AndroidNotificationAction(
        'view_event',
        '查看詳情',
        showsUserInterface: true,
      ));
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chingu_rich_notifications', // channel Id
      'Rich Notifications', // channel Name
      channelDescription: 'Notifications with images and actions',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: styleInformation,
      actions: actions,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // 構建 Payload
    final Map<String, dynamic> payload = {
      'actionType': notification.actionType,
      'actionData': notification.actionData,
      'notificationId': notification.id,
    };

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // 使用 hashCode 作為 ID
      notification.title,
      notification.message,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }
}

/// 簡單的路由資訊類
class RouteInfo {
  final String routeName;
  final Object? arguments;

  RouteInfo(this.routeName, [this.arguments]);
}
