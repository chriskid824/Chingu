import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/firestore_service.dart';
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
  StreamSubscription<List<NotificationModel>>? _subscription;
  DateTime? _lastCheckTime;

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

  /// 開始監聽通知
  void startListening(String userId) {
    // 停止之前的監聽
    stopListening();

    _lastCheckTime = DateTime.now();

    // 監聽最近的通知
    _subscription = NotificationStorageService()
        .watchNotifications(limit: 1)
        .listen((notifications) {
          _handleNewNotifications(userId, notifications);
        });

    debugPrint('Notification listener started for user: $userId');
  }

  /// 停止監聽
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('Notification listener stopped');
  }

  /// 處理新通知
  Future<void> _handleNewNotifications(String userId, List<NotificationModel> notifications) async {
    if (notifications.isEmpty) return;

    final notification = notifications.first;

    // 檢查是否是新通知 (createdAt > _lastCheckTime)
    // 確保只處理監聽開始後或上次檢查後的新通知
    if (_lastCheckTime != null &&
        notification.createdAt.isBefore(_lastCheckTime!)) {
      return;
    }

    // 更新最後檢查時間
    _lastCheckTime = DateTime.now();

    // 檢查用戶偏好
    final user = await FirestoreService().getUser(userId);
    if (user == null) return;

    // 1. 全局開關
    if (!user.pushNotificationsEnabled) return;

    // 2. 分類開關
    bool shouldNotify = false;

    switch (notification.type) {
      case 'match':
        // 目前系統僅在配對成功時發送 'match' 類型通知 (NotificationStorageService.createMatchNotification)
        // 因此這裡使用 matchSuccessNotification 開關
        // "新配對" (newMatchNotification) 用於單向喜歡，目前系統尚未產生此類通知，
        // 該開關暫時保留以備將來擴充，或與配對成功共用
        shouldNotify = user.matchSuccessNotification;
        break;
      case 'message':
        shouldNotify = user.newMessageNotification;
        break;
      case 'event':
        // 簡單判斷：如果是變更通知，通常標題或內容會包含"變更"
        // 注意：此判斷依賴文字內容，若文案修改可能失效。
        // TODO: 未來應在 NotificationModel 中增加 subtype 欄位以區分提醒與變更
        if (notification.title.contains('變更') || notification.message.contains('變更')) {
          shouldNotify = user.eventChangeNotification;
        } else {
          shouldNotify = user.eventReminderNotification;
        }
        break;
      case 'marketing':
        shouldNotify = user.marketingPromotionNotification;
        break;
      case 'newsletter':
        shouldNotify = user.newsletterNotification;
        break;
      case 'system':
      default:
        shouldNotify = true;
        break;
    }

    if (shouldNotify) {
      await showNotification(notification);
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
}
