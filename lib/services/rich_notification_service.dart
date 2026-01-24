import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';

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
  static String? initialRoute;
  static Object? initialArguments;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 檢查是否有通知啟動 App
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final response = notificationAppLaunchDetails!.notificationResponse;
      if (response != null && response.payload != null) {
        try {
          final Map<String, dynamic> data = json.decode(response.payload!);
          final String? actionType = data['actionType'];
          final String? actionData = data['actionData'];
          final String? actionId = response.actionId;

          String? targetAction;
          if (actionId != null && actionId != 'default') {
            targetAction = actionId;
          } else if (actionType != null) {
            targetAction = actionType;
          }

          if (targetAction != null) {
            final routeInfo = _getRouteForAction(targetAction, actionData);
            if (routeInfo != null) {
              initialRoute = routeInfo.$1;
              initialArguments = routeInfo.$2;
            }
          }
        } catch (e) {
          debugPrint('Error parsing notification payload on launch: $e');
        }
      }
    }

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

    _isInitialized = true;
  }

  /// 處理通知點擊事件
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType'];
        final String? actionData = data['actionData'];

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        _handleNavigation(actionType, actionData, actionId);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? actionId) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    String? targetAction;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      targetAction = actionId;
    } else if (actionType != null) {
      targetAction = actionType;
    }

    if (targetAction != null) {
      final routeInfo = _getRouteForAction(targetAction, actionData);
      if (routeInfo != null) {
        navigator.pushNamed(routeInfo.$1, arguments: routeInfo.$2);
      }
    }
  }

  (String, Object?)? _getRouteForAction(String action, String? data) {
    switch (action) {
      case 'open_chat':
        if (data != null) {
          // data 預期是 userId 或 chatRoomId
          // 暫時導航到聊天列表
          return (AppRoutes.chatList, null);
        } else {
          return (AppRoutes.chatList, null);
        }
      case 'view_event':
        if (data != null) {
           // 這裡應該是 eventId
          return (AppRoutes.eventDetail, null);
        }
        return (AppRoutes.eventDetail, null);
      case 'match_history':
        return (AppRoutes.matchesList, null);
      default:
        // 預設導航到通知頁面
        return (AppRoutes.notifications, null);
    }
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
