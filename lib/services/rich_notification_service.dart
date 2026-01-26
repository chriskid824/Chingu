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

        _handleNavigation(deeplink);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? deeplink) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    if (deeplink == null || deeplink.isEmpty) {
        navigator.pushNamed(AppRoutes.notifications);
        return;
    }

    // 簡單解析 deeplink
    // 假設 deeplink 格式為 "/chat_detail?id=123"
    // 或者直接是路徑

    // Check for chat
    if (deeplink.contains('chat_detail') || deeplink.contains('chat_list')) {
        // 暫時導航到聊天列表，因為 ChatDetailScreen 需要複雜參數
        navigator.pushNamed(AppRoutes.chatList);
    }
    // Check for event
    else if (deeplink.contains('event_detail')) {
        navigator.pushNamed(AppRoutes.eventDetail);
    }
    // Check for match history
    else if (deeplink.contains('matches')) {
        navigator.pushNamed(AppRoutes.matchesList);
    }
    else {
        // Default
        navigator.pushNamed(AppRoutes.notifications);
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
    if (notification.deeplink != null) {
        if (notification.deeplink!.contains('chat')) {
            actions.add(const AndroidNotificationAction(
                'open_chat',
                '回覆',
                showsUserInterface: true,
            ));
        } else if (notification.deeplink!.contains('event')) {
             actions.add(const AndroidNotificationAction(
                'view_event',
                '查看詳情',
                showsUserInterface: true,
            ));
        }
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
