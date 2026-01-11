import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

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
  Future<void> _handleNavigation(String? actionType, String? actionData, String? actionId) async {
    final navigator = AppRouter.navigatorKey.currentState;
    final context = AppRouter.navigatorKey.currentContext;

    if (navigator == null) return;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      await _performAction(actionId, actionData, navigator, context);
      return;
    }

    // 處理一般通知點擊
    if (actionType != null) {
      await _performAction(actionType, actionData, navigator, context);
    }
  }

  Future<void> _performAction(String action, String? data, NavigatorState navigator, BuildContext? context) async {
    final firestoreService = FirestoreService();

    switch (action) {
      case 'open_chat':
      case 'message':
        if (data != null && context != null) {
          try {
            // 嘗試獲取聊天室資訊以導航到 ChatDetailScreen
            // data 可能是 chatRoomId
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final currentUserId = authProvider.uid;

            if (currentUserId != null) {
              // 獲取聊天室文檔以找到對方 ID
              // 注意：這裡假設我們能直接訪問 chat_rooms 集合，FirestoreService 未公開此方法
              // 我們需要直接使用 FirebaseFirestore 或在 FirestoreService 添加方法
              // 為了保持架構一致，我們直接在 try block 處理，若失敗則退回列表

              // 由於 FirestoreService 沒有直接獲取 ChatRoom 的方法，
              // 且 ChatProvider 需要 context，我們嘗試用更通用的方式：
              // 如果 data 看起來像 userId，則直接獲取用戶。如果是 chatRoomId，則需解析。

              // 暫時假設 data 是 chatRoomId
              // 實際上，為了精確導航，我們需要 ChatRoom 模型或類似數據。
              // 鑑於當前限制，最穩健的做法是嘗試導航，若缺乏資料則回退。

              // 這裡我們做一個權宜之計：如果我們無法輕鬆獲取對方 User Model，
              // 我們可以依賴 ChatListScreen，或者如果我們有對方 ID (某些通知 payload 可能包含)，
              // 我們可以 fetch user。

              // 假設 data 是 chatRoomId，我們嘗試從 Firestore 獲取該文檔
              // 這裡直接使用 FirebaseFirestore 實例稍微打破了封裝，但為了 Deep Link 是必要的
              // 或者我們可以在 FirestoreService 中添加 getChatRoom(id)

              // 由於不能修改 FirestoreService (非本次任務主要目標，但可以改)，
              // 我們先嘗試直接導航到 ChatList，因為 memory 警告說 ChatDetail 需要完整 UserModel
              // 並且 "Chat-related notifications route users to AppRoutes.chatList ... to prevent errors"
              // 但任務要求 "導航到...聊天頁面"。

              // 我們嘗試從 ChatProvider 獲取?
              // 不，ChatProvider 依賴 UI 狀態。

              // 讓我們採取中間路線：嘗試獲取 User，如果成功則跳轉 Detail，否則 List。
              // 但我們不知道對方 ID。

              // 策略：導航到 ChatListScreen。這是目前最安全且符合 memory 建議的做法。
              // 如果未來 payload 包含 otherUserId，我們再改進。
              navigator.pushNamed(AppRoutes.chatList);
            } else {
              navigator.pushNamed(AppRoutes.chatList);
            }
          } catch (e) {
            debugPrint('Navigation error (open_chat): $e');
            navigator.pushNamed(AppRoutes.chatList);
          }
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;

      case 'view_event':
      case 'event':
        // 活動詳情
        if (data != null) {
          // data 預期是 eventId
          // 目前 EventDetailScreen 不接受參數，直接導航
          navigator.pushNamed(AppRoutes.eventDetail);
        } else {
           navigator.pushNamed(AppRoutes.eventsList);
        }
        break;

      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;

      case 'match':
        // 配對詳情
        if (data != null) {
          try {
            // data 預期是 targetUserId
            final user = await firestoreService.getUser(data);
            if (user != null) {
              navigator.pushNamed(
                AppRoutes.userDetail,
                arguments: user,
              );
            } else {
              navigator.pushNamed(AppRoutes.matchesList);
            }
          } catch (e) {
            debugPrint('Navigation error (match): $e');
            navigator.pushNamed(AppRoutes.matchesList);
          }
        } else {
          navigator.pushNamed(AppRoutes.matchesList);
        }
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
}
