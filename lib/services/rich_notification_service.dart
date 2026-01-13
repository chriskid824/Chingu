import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../core/routes/app_router.dart';
import '../services/firestore_service.dart';

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
    switch (action) {
      case 'open_chat':
        if (data != null) {
          try {
            // 嘗試解析 data，如果是 JSON
            Map<String, dynamic> chatData = {};
            String chatRoomId = data;

            try {
              final decoded = json.decode(data);
              if (decoded is Map<String, dynamic>) {
                chatData = decoded;
                if (chatData.containsKey('chatRoomId')) {
                  chatRoomId = chatData['chatRoomId'];
                }
              }
            } catch (_) {
              // data 不是 JSON，假設它是 ID
            }

            final currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser == null) {
              navigator.pushNamed(AppRoutes.chatList);
              return;
            }

            // 獲取聊天室資料以找到對方 ID
            final chatRoomDoc = await FirebaseFirestore.instance
                .collection('chat_rooms')
                .doc(chatRoomId)
                .get();

            if (!chatRoomDoc.exists) {
               navigator.pushNamed(AppRoutes.chatList);
               return;
            }

            final participants = List<String>.from(chatRoomDoc['participantIds'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUser.uid,
              orElse: () => '',
            );

            if (otherUserId.isNotEmpty) {
              final otherUser = await FirestoreService().getUser(otherUserId);
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
          } catch (e) {
            debugPrint('Error navigating to chat: $e');
            navigator.pushNamed(AppRoutes.chatList);
          }
        } else {
          navigator.pushNamed(AppRoutes.chatList);
        }
        break;

      case 'view_event':
        if (data != null) {
           // 導航到活動詳情，並傳遞 eventId (data)
          navigator.pushNamed(AppRoutes.eventDetail, arguments: data);
        }
        break;

      case 'match_success':
      case 'view_profile':
        if (data != null) {
          try {
            // data 可能是 userId
            final user = await FirestoreService().getUser(data);
            if (user != null) {
              navigator.pushNamed(AppRoutes.userDetail, arguments: user);
            } else {
               navigator.pushNamed(AppRoutes.matchesList);
            }
          } catch (e) {
             debugPrint('Error navigating to profile: $e');
             navigator.pushNamed(AppRoutes.matchesList);
          }
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
