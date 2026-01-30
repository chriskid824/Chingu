import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/routes/app_router.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../firebase_options.dart';

// 必須是 top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> initialize() async {
    // 請求通知權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 設置互動訊息處理 (背景開啟與終止狀態開啟)
    setupInteractedMessage();
  }

  void setupInteractedMessage() async {
    // 處理從終止狀態開啟 App
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 處理從背景狀態開啟 App
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  void _handleMessage(RemoteMessage message) async {
    debugPrint('_handleMessage: ${message.data}');

    // 確保 Navigator 已準備就緒 (解決 Race Condition)
    if (AppRouter.navigatorKey.currentState == null) {
      debugPrint('Navigator is null, waiting...');
      await Future.delayed(const Duration(milliseconds: 1000));
      if (AppRouter.navigatorKey.currentState == null) {
        debugPrint('Navigator is still null, aborting navigation.');
        return;
      }
    }

    final data = message.data;
    final type = data['type'] ?? data['actionType']; // 兼容舊版 actionType

    if (type == 'chat' || type == 'open_chat') {
      final chatRoomId = data['chatRoomId'] ?? data['actionData']; // 兼容 actionData
      // 如果是用戶ID (舊版邏輯)，這裡可能需要調整，但暫時假設是 chatRoomId
      // 實際上我們需要 senderId 來獲取 otherUser，但 notification payload 有時只有 title/body/chatRoomId
      // 如果沒有 senderId，嘗試從 chatRoomId 獲取聊天室資料?

      final senderId = data['senderId'];

      if (chatRoomId != null && senderId != null) {
        // 需要獲取對方資料才能導航到聊天詳情頁
        try {
          final userModel = await _firestoreService.getUser(senderId);
          if (userModel != null) {
             AppRouter.navigatorKey.currentState?.pushNamed(
              AppRoutes.chatDetail,
              arguments: {
                'chatRoomId': chatRoomId,
                'otherUser': userModel,
              },
            );
          } else {
             AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.chatList);
          }
        } catch (e) {
          debugPrint('Error fetching user for notification navigation: $e');
          AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.chatList);
        }
      } else {
         // 如果資料不足，導航到列表
         AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.chatList);
      }
    } else if (type == 'match_success' || type == 'match_history') {
       AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.matchesList);
    } else if (type == 'view_event') {
       AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.eventDetail);
    } else {
      // 預設導航到通知列表
       AppRouter.navigatorKey.currentState?.pushNamed(AppRoutes.notifications);
    }
  }

  Future<void> updateFCMToken(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 監聽 Token 刷新
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
         await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
