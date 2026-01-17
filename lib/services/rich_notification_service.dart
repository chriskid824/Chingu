import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../core/routes/app_router.dart';
import '../models/user_model.dart';
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
        final String? type = data['type'];

        // 如果是點擊按鈕，actionId 會是按鈕的 ID
        final String? actionId = response.actionId;

        _handleNavigation(actionType, actionData, actionId, type);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// 處理導航邏輯
  void _handleNavigation(String? actionType, String? actionData, String? actionId, String? type) {
    final navigator = AppRouter.navigatorKey.currentState;
    if (navigator == null) return;

    // 優先處理按鈕點擊
    if (actionId != null && actionId != 'default') {
      _performAction(actionId, actionData, navigator, type);
      return;
    }

    // 處理一般通知點擊
    // 優先使用 actionType，如果沒有則使用 notification type
    _performAction(actionType ?? '', actionData, navigator, type);
  }

  void _performAction(String action, String? data, NavigatorState navigator, String? type) async {
    // 根據 type 和 action 決定導航
    // 1. Chat (Message)
    if (action == 'open_chat' || type == 'message') {
      if (data != null) {
        // data 應該是 userId (sender) 或 chatRoomId
        await _navigateToChat(navigator, data);
      } else {
        navigator.pushNamed(AppRoutes.chatList);
      }
      return;
    }

    // 2. Event (View Event)
    if (action == 'view_event' || type == 'event') {
      if (data != null) {
        navigator.pushNamed(AppRoutes.eventDetail, arguments: {'eventId': data});
      }
      return;
    }

    // 3. Match (Match Detail)
    if (action == 'match_history' || action == 'view_profile' || type == 'match') {
       if (data != null) {
         // data 是 partnerId
         navigator.pushNamed(AppRoutes.userDetail, arguments: {'userId': data});
       } else {
         navigator.pushNamed(AppRoutes.matchesList);
       }
       return;
    }

    // Default fallback
    switch (action) {
      case 'match_history':
        navigator.pushNamed(AppRoutes.matchesList);
        break;
      default:
        // 預設導航到通知頁面
        navigator.pushNamed(AppRoutes.notifications);
        break;
    }
  }

  Future<void> _navigateToChat(NavigatorState navigator, String data) async {
    // data 可能是 chatRoomId 或 userId
    // 嘗試判斷：如果是 userId (通常較短或特定格式) vs chatRoomId
    // 這裡我們假設 notification payload 中 actionData 是 senderId (for message type)
    // 因為通常後端通知會告訴你是誰傳的

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
       navigator.pushNamed(AppRoutes.chatList);
       return;
    }

    String? chatRoomId;
    UserModel? otherUser;

    try {
      // 假設 data 是 userId (senderId)
      // 嘗試獲取該 User
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(data).get();
      if (userDoc.exists) {
        otherUser = UserModel.fromMap(userDoc.data()!, userDoc.id);

        // 嘗試獲取或創建 ChatRoom
        // 這裡我們不想創建新的，而是查找現有的
        chatRoomId = await ChatService().createChatRoom(currentUser.uid, otherUser.uid);
      } else {
        // 如果找不到 user，也許 data 是 chatRoomId?
        // 嘗試獲取 ChatRoom
        final chatDoc = await FirebaseFirestore.instance.collection('chat_rooms').doc(data).get();
        if (chatDoc.exists) {
           chatRoomId = data;
           // 從 chatRoom 獲取 otherUser
           final chatData = chatDoc.data() as Map<String, dynamic>;
           final participants = List<String>.from(chatData['participantIds'] ?? []);
           final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
           if (otherUserId.isNotEmpty) {
             final otherUserDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
             if (otherUserDoc.exists) {
               otherUser = UserModel.fromMap(otherUserDoc.data()!, otherUserDoc.id);
             }
           }
        }
      }

      if (chatRoomId != null && otherUser != null) {
        navigator.pushNamed(
          AppRoutes.chatDetail,
          arguments: {
            'chatRoomId': chatRoomId,
            'otherUser': otherUser,
          },
        );
      } else {
         debugPrint('Could not navigate to chat: chatRoomId or otherUser missing');
         navigator.pushNamed(AppRoutes.chatList);
      }
    } catch (e) {
      debugPrint('Error navigating to chat: $e');
      navigator.pushNamed(AppRoutes.chatList);
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
      'type': notification.type, // Add type to payload
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
