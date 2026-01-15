import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

    _setupRemoteNotifications();

    _isInitialized = true;
  }

  /// 設置遠端通知監聽
  void _setupRemoteNotifications() {
    // 處理 App 從終止狀態被打開
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleRemoteMessage(message);
      }
    });

    // 處理 App 在背景時被點擊打開
    FirebaseMessaging.onMessageOpenedApp.listen(_handleRemoteMessage);
  }

  /// 處理遠端訊息
  void _handleRemoteMessage(RemoteMessage message) {
    debugPrint('Handling remote message: ${message.data}');
    final data = message.data;

    // 優先使用 type，其次是 actionType
    final String? actionType = data['type'] ?? data['actionType'];

    // 嘗試獲取 actionData，如果沒有則將整個 data 視為 actionData
    String? actionData = data['actionData'];
    if (actionData == null) {
      // 排除一些非數據欄位
      final Map<String, dynamic> cleanData = Map.from(data)
        ..remove('type')
        ..remove('actionType')
        ..remove('click_action');

      if (cleanData.isNotEmpty) {
        actionData = json.encode(cleanData);
      }
    }

    _handleNavigation(actionType, actionData, null);
  }

  /// 處理通知點擊事件 (本地通知)
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = json.decode(response.payload!);
        final String? actionType = data['actionType']; // 本地通知 payload 使用 actionType
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
    if (navigator == null) {
       // 如果 navigator 還沒準備好 (例如冷啟動)，這可能會發生
       // 實際應用中可能需要延遲處理或儲存 pending action
       Future.delayed(const Duration(seconds: 1), () {
         _handleNavigation(actionType, actionData, actionId);
       });
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
    debugPrint('Performing action: $action with data: $data');
    switch (action) {
      case 'match':
      case 'match_history': // Legacy
        // 嘗試導航到聊天頁面 (如果有的話)，否則去配對列表
        bool navigated = false;
        if (data != null) {
          try {
            final Map<String, dynamic> args = _parseData(data);
            if (args.containsKey('chatRoomId')) {
              navigator.pushNamed(
                AppRoutes.chatDetail,
                arguments: {
                  'chatRoomId': args['chatRoomId'],
                  'otherUserId': args['otherUserId'],
                  'otherUser': null,
                },
              );
              navigated = true;
            }
          } catch (e) {
            debugPrint('Error parsing match data: $e');
          }
        }

        if (!navigated) {
          navigator.pushNamed(AppRoutes.matchesList);
        }
        break;

      case 'chat':
      case 'open_chat': // Legacy
      case 'message':
        if (data != null) {
          try {
            final Map<String, dynamic> args = _parseData(data);
            if (args.containsKey('chatRoomId')) {
              navigator.pushNamed(
                AppRoutes.chatDetail,
                arguments: {
                  'chatRoomId': args['chatRoomId'],
                  'otherUserId': args['otherUserId'],
                  // 如果有 senderId 也可能是 otherUserId
                  'otherUser': null,
                },
              );
            } else {
              navigator.pushNamed(AppRoutes.chatList);
            }
          } catch (e) {
             debugPrint('Error parsing chat data: $e');
             navigator.pushNamed(AppRoutes.chatList);
          }
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;

      case 'event':
      case 'view_event': // Legacy
        if (data != null) {
           // 這裡應該是 eventId
           // 目前 EventDetailScreen 不接受參數，但我們保留擴充性
           try {
             // 嘗試解析一下，雖然後續沒用到
             _parseData(data);
           } catch (_) {}

          navigator.pushNamed(AppRoutes.eventDetail);
        }
        break;

      default:
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  Map<String, dynamic> _parseData(String data) {
    try {
      return json.decode(data);
    } catch (e) {
      // 如果不是 JSON，假設它本身就是 ID?
      // 這裡回傳空 map 避免錯誤
      return {};
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
    // 為了保持一致性，這裡 actionType 對應 _performAction 的 switch case
    // NotificationModel 的 actionType 可能是 'open_chat'，我們在 switch 中有處理
    final Map<String, dynamic> payload = {
      'actionType': notification.actionType ?? notification.type, // 如果 actionType 空，使用 type
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
