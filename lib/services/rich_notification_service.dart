import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
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

  /// 檢查應用程式是否由通知啟動
  Future<void> checkInitialNotification() async {
    // 1. 檢查 Local Notification 啟動
    final NotificationAppLaunchDetails? launchDetails =
        await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (launchDetails != null &&
        launchDetails.didNotificationLaunchApp &&
        launchDetails.notificationResponse != null) {
      _onNotificationTap(launchDetails.notificationResponse!);
      return;
    }

    // 2. 檢查 FCM 啟動 (當 app 完全關閉時)
    try {
      final RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();

      if (initialMessage != null) {
        // 構建類似的 payload
        // 注意: FCM data 都是 String，如果 actionData 是 JSON 字串，直接傳遞即可
        final String? actionType = initialMessage.data['actionType'];
        final String? actionData = initialMessage.data['actionData'];

        if (actionType != null) {
          _handleNavigation(actionType, actionData, null);
        }
      }
    } catch (e) {
      debugPrint('Error checking initial FCM message: $e');
    }
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

  Future<void> _performAction(String action, String? data, NavigatorState navigator) async {
    try {
      switch (action) {
        case 'open_chat':
          if (data != null) {
            Map<String, dynamic> args = {};
            String? otherUserId;

            // 嘗試解析 JSON
            try {
              final parsedData = json.decode(data);
              if (parsedData is Map<String, dynamic>) {
                args['chatRoomId'] = parsedData['chatRoomId'];
                otherUserId = parsedData['otherUserId'];
              } else {
                // 假設 data 是 chatRoomId
                args['chatRoomId'] = data;
              }
            } catch (_) {
              // 解析失敗，假設 data 是 chatRoomId
              args['chatRoomId'] = data;
            }

            // 如果有 otherUserId，獲取用戶資料
            if (otherUserId != null) {
              final user = await _fetchUser(otherUserId);
              if (user != null) {
                args['otherUser'] = user;
                navigator.pushNamed(AppRoutes.chatDetail, arguments: args);
                return;
              }
            } else if (args['chatRoomId'] != null) {
               // 如果只有 chatRoomId，嘗試導航 (ChatDetailScreen 可能需要額外處理或失敗)
               // 理想情況下應該先 fetch chatRoom 獲取 otherUserId，這裡簡化處理
               // 降級到聊天列表
               navigator.pushNamed(AppRoutes.chatList);
               return;
            }

            navigator.pushNamed(AppRoutes.chatList);
          } else {
            navigator.pushNamed(AppRoutes.chatList);
          }
          break;

        case 'match':
        case 'match_success':
          if (data != null) {
            // data 預期是 userId
            String userId = data;
             try {
              final parsedData = json.decode(data);
              if (parsedData is Map<String, dynamic> && parsedData.containsKey('userId')) {
                userId = parsedData['userId'];
              }
            } catch (_) {}

            final user = await _fetchUser(userId);
            // 導航到配對詳情 (UserDetailScreen)
            // 即使 UserDetailScreen 目前可能是硬編碼的，我們還是傳遞參數以備將來支援
            navigator.pushNamed(AppRoutes.userDetail, arguments: user);
          } else {
             navigator.pushNamed(AppRoutes.matchesList);
          }
          break;

        case 'view_event':
          // 導航到活動詳情
          // 如果 EventDetailScreen 支援參數，這裡應該傳遞
          navigator.pushNamed(AppRoutes.eventDetail, arguments: data);
          break;

        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;

        case 'navigate':
           if (data != null) {
             navigator.pushNamed(data);
           }
           break;

        default:
          // 預設導航到通知頁面
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } catch (e) {
      debugPrint('Error performing notification action: $e');
      navigator.pushNamed(AppRoutes.home);
    }
  }

  /// 輔助方法：獲取用戶資料
  Future<UserModel?> _fetchUser(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching user for notification: $e');
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
