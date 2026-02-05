import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/routes/app_router.dart';
import '../services/chat_service.dart';

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

    // 初始化 FCM
    await setupFirebaseMessaging();

    _isInitialized = true;
  }

  /// 設置 Firebase Messaging 監聽器
  Future<void> setupFirebaseMessaging() async {
    // 1. 處理應用在背景時點擊通知
    FirebaseMessaging.onMessageOpenedApp.listen(_handleFCMNavigation);

    // 2. 處理應用在前台收到通知
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // 這裡可以選擇顯示本地通知，或者只更新徽章等
      // 如果通知包含 notification 屬性，Firebase SDK 可能會自動顯示通知（取決於平台）
      // 我們手動顯示以確保一致的 UI 和行為
      if (message.notification != null) {
        _showRemoteNotification(message);
      }
    });

    // 3. 處理應用從終止狀態啟動
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _pendingInitialMessage = initialMessage;
    }
  }

  /// 檢查並處理待處理的初始通知
  Future<void> checkPendingNotification() async {
    if (_pendingInitialMessage != null) {
      debugPrint('Processing pending initial notification');
      _handleFCMNavigation(_pendingInitialMessage!);
      _pendingInitialMessage = null;
    }
  }

  /// 顯示來自 FCM 的遠程通知
  Future<void> _showRemoteNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;
    final data = message.data;

    if (notification != null) {
      // 構建 NotificationModel 來重用 showNotification 邏輯
      final model = NotificationModel(
        id: message.messageId ?? DateTime.now().toString(),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        type: data['type'] ?? 'system',
        title: notification.title ?? '',
        message: notification.body ?? '',
        imageUrl: android?.imageUrl ?? data['imageUrl'],
        actionType: data['actionType'],
        actionData: data['actionData'],
        createdAt: DateTime.now(),
      );

      await showNotification(model);
    }
  }

  /// 處理 FCM 導航邏輯
  void _handleFCMNavigation(RemoteMessage message) {
    final data = message.data;
    final String? actionType = data['actionType'];
    final String? actionData = data['actionData'];

    // 如果沒有 actionType 但有 type，也可以根據 type 導航
    final String? type = data['type'];

    _handleNavigation(actionType ?? type, actionData, null);
  }

  /// 處理通知點擊事件 (本地通知)
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType'];
        final String? actionData = data['actionData'];
        final String? type = data['type'];

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        _handleNavigation(actionType ?? type, actionData, actionId);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  Future<void> _handleNavigation(String? actionType, String? actionData, String? actionId) async {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      await _performAction(actionId, actionData, navigator);
      return;
    }

    // 處理一般通知點擊
    if (actionType != null) {
      await _performAction(actionType, actionData, navigator);
    }
  }

  Future<void> _performAction(String action, String? data, NavigatorState navigator) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // 如果未登入，導航到登入頁面
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
      return;
    }

    switch (action) {
      case 'open_chat':
      case 'message': // 兼容 type
        if (data != null) {
          try {
            // data 是目標用戶 ID
            final targetUserId = data;

            // 獲取目標用戶資料
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .get();

            if (userDoc.exists) {
              final otherUser = UserModel.fromMap(userDoc.data()!, targetUserId);

              // 獲取或創建聊天室
              final chatRoomId = await ChatService().createChatRoom(
                currentUser.uid,
                targetUserId,
              );

              // 導航到聊天詳情頁
              navigator.pushNamed(
                AppRoutes.chatDetail,
                arguments: {
                  'chatRoomId': chatRoomId,
                  'otherUser': otherUser,
                },
              );
            }
          } catch (e) {
            debugPrint('Error navigating to chat: $e');
            navigator.pushNamed(AppRoutes.chatList);
          }
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;

      case 'view_event':
      case 'event': // 兼容 type
        if (data != null) {
           navigator.pushNamed(
             AppRoutes.eventDetail,
             arguments: {'eventId': data},
           );
        } else {
          navigator.pushNamed(AppRoutes.eventsList);
        }
        break;

      case 'view_match':
      case 'match': // 兼容 type
        if (data != null) {
          navigator.pushNamed(
            AppRoutes.userDetail,
            arguments: {'userId': data},
          );
        } else {
          navigator.pushNamed(AppRoutes.matchesList);
        }
        break;

      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
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
    if (notification.actionType == 'open_chat' || notification.type == 'message') {
      actions.add(const AndroidNotificationAction(
        'open_chat',
        '回覆',
        showsUserInterface: true,
      ));
    } else if (notification.actionType == 'view_event' || notification.type == 'event') {
      actions.add(const AndroidNotificationAction(
        'view_event',
        '查看詳情',
        showsUserInterface: true,
      ));
    } else if (notification.actionType == 'view_match' || notification.type == 'match') {
      actions.add(const AndroidNotificationAction(
        'view_match',
        '查看',
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
      'type': notification.type, // Add type for fallback
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
