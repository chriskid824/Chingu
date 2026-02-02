import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
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
  Future<void> _handleNavigation(
      String? actionType, String? actionData, String? actionId) async {
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

  Future<void> _performAction(
      String action, String? data, NavigatorState navigator) async {
    try {
      final firestoreService = FirestoreService();

      switch (action) {
        case 'open_chat':
          if (data != null) {
            Map<String, dynamic> parsedData = {};
            try {
              parsedData = json.decode(data);
            } catch (_) {
              // fallback if data is not JSON
            }

            final String? chatRoomId = parsedData['chatRoomId'];
            final String? otherUserId = parsedData['otherUserId'] ??
                parsedData['senderId'] ??
                parsedData['partnerId'];

            if (chatRoomId != null && otherUserId != null) {
              final otherUser = await firestoreService.getUser(otherUserId);
              if (otherUser != null) {
                navigator.pushNamed(
                  AppRoutes.chatDetail,
                  arguments: {
                    'chatRoomId': chatRoomId,
                    'otherUser': otherUser,
                  },
                );
                return;
              }
            }
            navigator.pushNamed(AppRoutes.chatList);
          } else {
            navigator.pushNamed(AppRoutes.chatList);
          }
          break;

        case 'view_match':
        case 'match': // Handle both potential action types
          if (data != null) {
            Map<String, dynamic> parsedData = {};
            try {
              parsedData = json.decode(data);
            } catch (_) {
              // fallback if data is not JSON
            }

            final String? chatRoomId = parsedData['chatRoomId'];
            final String? partnerId = parsedData['partnerId'] ??
                parsedData['otherUserId'] ??
                parsedData['senderId'];

            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            if (chatRoomId != null &&
                partnerId != null &&
                currentUserId != null) {
              final currentUser = await firestoreService.getUser(currentUserId);
              final partner = await firestoreService.getUser(partnerId);

              if (currentUser != null && partner != null) {
                navigator.pushNamed(
                  AppRoutes.matchSuccess,
                  arguments: {
                    'currentUser': currentUser,
                    'partner': partner,
                    'chatRoomId': chatRoomId,
                  },
                );
                return;
              }
            }
            navigator.pushNamed(AppRoutes.matchesList);
          } else {
            navigator.pushNamed(AppRoutes.matchesList);
          }
          break;

        case 'view_event':
        case 'event': // Handle both potential action types
          navigator.pushNamed(AppRoutes.eventDetail);
          break;

        case 'match_history':
          navigator.pushNamed(AppRoutes.matchesList);
          break;

        default:
          // 預設導航到通知頁面
          navigator.pushNamed(AppRoutes.notifications);
          break;
      }
    } catch (e) {
      debugPrint('Error handling notification action: $e');
      // Fallback to notification screen on error
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
