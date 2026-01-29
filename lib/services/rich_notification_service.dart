import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling a background message: ${message.messageId}');
}

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
  RemoteMessage? _pendingInitialMessage;

  /// 初始化通知服務 (包含 Local Notifications 和 FCM)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 初始化 Local Notifications
    await _initializeLocalNotifications();

    // 2. 初始化 FCM
    await _initializeFCM();

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
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
  }

  Future<void> _initializeFCM() async {
    // 請求 FCM 權限
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 設定背景處理程序
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 獲取並儲存 Initial Message (Terminated -> Open)
    _pendingInitialMessage = await FirebaseMessaging.instance.getInitialMessage();

    // 監聽前台訊息 (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint('Message also contained a notification: ${message.notification}');
      }

      // 顯示本地通知
      final notificationModel = _createNotificationModelFromRemoteMessage(message);
      showNotification(notificationModel);
    });

    // 監聽背景開啟 App (Background -> Open)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
      _handleRemoteNavigation(message);
    });
  }

  /// 檢查並消費 Initial Message (在 App UI 準備好後調用)
  void checkAndConsumeInitialMessage() {
    if (_pendingInitialMessage != null) {
      debugPrint('Consuming initial message: ${_pendingInitialMessage!.messageId}');
      _handleRemoteNavigation(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  // Helper to convert RemoteMessage to NotificationModel
  NotificationModel _createNotificationModelFromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: '', // Not needed for display
      type: data['type'] ?? 'system',
      title: notification?.title ?? data['title'] ?? '通知',
      message: notification?.body ?? data['body'] ?? '',
      imageUrl: data['imageUrl'] ?? (notification?.android?.imageUrl ?? notification?.apple?.imageUrl),
      actionType: data['actionType'],
      actionData: data['actionData'],
      isRead: false,
      createdAt: message.sentTime ?? DateTime.now(),
    );
  }

  void _handleRemoteNavigation(RemoteMessage message) {
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];
    _handleNavigation(actionType, actionData, null);
  }

  /// 處理通知點擊事件 (Local Notification Tap)
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType'];
        final String? actionData = data['actionData'];
        final String? actionId = response.actionId;

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionIdToUse = actionId;

        _handleNavigation(actionType, actionData, actionIdToUse);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? actionId) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) {
        debugPrint('Navigator state is null, cannot navigate');
        return;
    }

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      _performAction(actionId, actionData, navigator);
      return;
    }

    // 處理一般通知點擊
    if (actionType != null) {
      _performAction(actionType, actionData, navigator);
    }
  }

  void _performAction(String action, String? data, NavigatorState navigator) {
    switch (action) {
      case 'open_chat':
        if (data != null) {
          // data 預期是 userId 或 chatRoomId
          // 這裡假設需要構建參數，具體視 ChatDetailScreen 需求
          // 由於 ChatDetailScreen 需要 arguments (UserModel or Map)，這裡可能需要調整
          // 暫時導航到聊天列表
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        if (data != null) {
           // 這裡應該是 eventId，但 EventDetailScreen 目前似乎不接受參數
           // 根據 memory 描述，EventDetailScreen 使用 hardcoded data
           // 但為了兼容性，我們先嘗試導航
          navigator.pushNamed(AppRoutes.eventDetail);
        }
        break;
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList); // 根據 memory 修正路徑
        break;
      default:
        // 預設導航到通知頁面
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

  /// 獲取 FCM Token
  Future<String?> getFCMToken() async {
    return await FirebaseMessaging.instance.getToken();
  }
}
