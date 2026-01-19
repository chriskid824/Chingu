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
        final String? actionType = data['actionType']; // Legacy support
        final String? actionData = data['actionData']; // Legacy support

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        // 優先處理按鈕點擊
        if (actionId != null && actionId != 'default') {
          // 對於按鈕點擊，我們可能需要根據 actionId 執行特定操作
          // 這裡暫時維持原有的 _performAction 邏輯，但需要適配 deeplink
          _handleNavigation(actionId, actionData, deeplink);
          return;
        }

        _handleNavigation(actionType, actionData, deeplink);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? deeplink) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (deeplink != null) {
      _handleDeeplink(deeplink, navigator);
      return;
    }

    if (actionType != null) {
      _performLegacyAction(actionType, actionData, navigator);
    }
  }

  void _handleDeeplink(String deeplink, NavigatorState navigator) {
    // 簡單的 deeplink 解析
    // 假設格式: chingu://{path}/{id} or just path
    // 為了簡單起見，我們只檢查關鍵字

    if (deeplink.contains('chat')) {
       navigator.pushNamed(AppRoutes.chatList);
    } else if (deeplink.contains('event')) {
       navigator.pushNamed(AppRoutes.eventDetail);
    } else if (deeplink.contains('match')) {
       navigator.pushNamed(AppRoutes.matchesList);
    } else {
       navigator.pushNamed(AppRoutes.notifications);
    }
  }

  void _performLegacyAction(String action, String? data, NavigatorState navigator) {
    switch (action) {
      case 'open_chat':
        navigator.pushNamed(AppRoutes.chatList);
        break;
      case 'view_event':
        navigator.pushNamed(AppRoutes.eventDetail);
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
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
    // 這裡我們根據 deeplink 或 type 來決定按鈕
    List<AndroidNotificationAction> actions = [];

    // 這裡的邏輯需要適配新的 deeplink
    // 假設 deeplink 包含 chat，則顯示回覆按鈕
    if (notification.deeplink?.contains('chat') == true) {
      actions.add(const AndroidNotificationAction(
        'open_chat',
        '回覆',
        showsUserInterface: true,
      ));
    } else if (notification.deeplink?.contains('event') == true) {
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
      'deeplink': notification.deeplink,
      'notificationId': notification.id,
      // 保留 legacy 字段以防萬一
      'actionType': _deriveActionType(notification),
      'actionData': null,
    };

    await _flutterLocalNotificationsPlugin.show(
      notification.id.hashCode, // 使用 hashCode 作為 ID
      notification.title,
      notification.content,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }

  String? _deriveActionType(NotificationModel n) {
    if (n.deeplink == null) return null;
    if (n.deeplink!.contains('chat')) return 'open_chat';
    if (n.deeplink!.contains('event')) return 'view_event';
    if (n.deeplink!.contains('match')) return 'match_history';
    return null;
  }
}
