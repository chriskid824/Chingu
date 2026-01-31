import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

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
  StreamSubscription<RemoteMessage>? _messageSubscription;

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

  /// 初始化 Firebase Messaging 監聽器
  ///
  /// 必須在 Widget 樹中有 AuthProvider 的地方調用
  void initFirebaseMessaging(BuildContext context) {
    _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message, context);
    });
  }

  /// 釋放資源
  void dispose() {
    _messageSubscription?.cancel();
  }

  /// 處理前台訊息並根據用戶偏好過濾
  void _handleForegroundMessage(RemoteMessage message, BuildContext context) {
    // 獲取當前用戶設定
    AuthProvider? authProvider;
    try {
      // 使用 listen: false 因為我們在 callback 中，不需要監聽變化
      authProvider = Provider.of<AuthProvider>(context, listen: false);
    } catch (e) {
      debugPrint('RichNotificationService: AuthProvider not found in context: $e');
      return;
    }

    final user = authProvider.userModel;
    if (user == null) {
       debugPrint('RichNotificationService: User not logged in, suppressing notification');
       return;
    }

    final data = message.data;
    // 如果 data['type'] 不存在，嘗試從 notification 標題猜測或預設為 system
    final type = data['type'] ?? 'system';

    // 根據偏好過濾
    if (!_shouldShowNotification(user, type, data)) {
      debugPrint('RichNotificationService: Notification suppressed by user preference (Type: $type)');
      return;
    }

    // 構建 NotificationModel
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      type: type,
      title: message.notification?.title ?? data['title'] ?? '通知',
      message: message.notification?.body ?? data['body'] ?? '',
      imageUrl: data['imageUrl'],
      actionType: data['actionType'],
      actionData: data['actionData'],
      createdAt: DateTime.now(),
    );

    showNotification(notification);
  }

  /// 檢查是否應該顯示通知
  bool _shouldShowNotification(UserModel user, String type, Map<String, dynamic> data) {
    switch (type) {
      case 'match':
        // 嘗試區分新配對和配對成功
        if (data['subtype'] == 'success' || data['status'] == 'success') {
          return user.notifyMatchSuccess;
        }
        return user.notifyNewMatch;

      case 'message':
        return user.notifyNewMessage;

      case 'event':
        // 嘗試區分提醒和變更
        if (data['subtype'] == 'change' || data['status'] == 'change') {
          return user.notifyDinnerChanges;
        }
        return user.notifyDinnerReminder;

      case 'promotion':
        return user.notifyPromotions;

      case 'newsletter':
        return user.notifyNewsletter;

      case 'system':
      default:
        // 系統通知預設顯示
        return true;
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
          navigator.pushNamed(AppRoutes.chatList);
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;
      case 'view_event':
        if (data != null) {
          navigator.pushNamed(AppRoutes.eventDetail);
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
