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

    _isInitialized = true;
  }

  /// 處理通知點擊事件
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? deeplink = data['deeplink'];
        // actionId handling omitted for simplicity as we use main deeplink for now

        if (deeplink != null) {
             _handleDeeplink(deeplink);
        } else {
             // Fallback for old payload format
             final String? actionType = data['actionType'];
             final String? actionData = data['actionData'];
             _handleLegacyAction(actionType, actionData);
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  void _handleDeeplink(String deeplink) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    try {
        final Uri uri = Uri.parse(deeplink);
        if (uri.path == '/chat-detail') {
             final userId = uri.queryParameters['userId'];
             if (userId != null) {
                 navigator.pushNamed(AppRoutes.chatDetail, arguments: {'userId': userId});
             } else {
                 navigator.pushNamed(AppRoutes.chatList);
             }
        } else if (uri.path == '/event-detail') {
            final eventId = uri.queryParameters['eventId'];
            if (eventId != null) {
                 navigator.pushNamed(AppRoutes.eventDetail, arguments: {'eventId': eventId});
            } else {
                 navigator.pushNamed(AppRoutes.eventsList);
            }
        } else {
            // Default fallback
            navigator.pushNamed(AppRoutes.notifications);
        }
    } catch (e) {
        debugPrint('Error handling deeplink: $e');
        navigator.pushNamed(AppRoutes.notifications);
    }
  }

  void _handleLegacyAction(String? actionType, String? actionData) {
     final navigator = AppRouter.navigatorKey.currentState;
     if (navigator == null) return;

    switch (actionType) {
      case 'open_chat':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.chatDetail, arguments: {'userId': actionData});
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        if (actionData != null) {
          navigator.pushNamed(AppRoutes.eventDetail, arguments: {'eventId': actionData});
        } else {
          navigator.pushNamed(AppRoutes.eventsList);
        }
        break;
      default:
        navigator.pushNamed(AppRoutes.notifications);
        break;
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
          summaryText: notification.content,
          hideExpandedLargeIcon: true,
        );
      } catch (e) {
        debugPrint('Error downloading image for notification: $e');
        // 圖片下載失敗則降級為普通通知
        styleInformation = BigTextStyleInformation(notification.content);
      }
    } else {
      styleInformation = BigTextStyleInformation(notification.content);
    }

    // 定義操作按鈕
    List<AndroidNotificationAction> actions = [];
    if (notification.type == NotificationType.message) {
      actions.add(const AndroidNotificationAction(
        'open_chat',
        '回覆',
        showsUserInterface: true,
      ));
    } else if (notification.type == NotificationType.event) {
      actions.add(const AndroidNotificationAction(
        'view_event',
        '查看詳情',
        showsUserInterface: true,
      ));
    } else if (notification.type == NotificationType.match) {
       actions.add(const AndroidNotificationAction(
        'open_chat',
        '打招呼',
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
      'deeplink': notification.deeplink,
      'notificationId': notification.id,
    };

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // 使用 hashCode 作為 ID
      notification.title,
      notification.content,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }
}
