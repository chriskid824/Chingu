import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/services/firestore_service.dart';

/// Top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

/// NotificationService: 管理 FCM 整合與遠端通知發送
///
/// 負責:
/// 1. 初始化 FCM 與權限請求
/// 2. 管理 FCM Token
/// 3. 通過 Cloud Functions 發送遠端通知
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// 初始化通知服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. 請求權限
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('User granted notification permission: ${settings.authorizationStatus}');

    // 2. 設置背景訊息處理器
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. 獲取並保存 Token (如果已經登錄)
    // 注意: 通常由 AuthProvider 在登錄後調用 saveToken
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      debugPrint('Initial FCM Token: $token');
    }

    // 4. 監聽 Token 刷新
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      // 這裡應該調用 updateFcmToken，但需要 userId。
      // 通常我們會通過 AuthProvider 或在 app 啟動時檢查 auth state。
      // 為簡單起見，這裡只打印，依賴 AuthProvider 的管理。
    });

    _isInitialized = true;
  }

  /// 更新用戶的 FCM Token
  Future<void> updateFcmToken(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _firestoreService.updateFcmToken(userId, token);
    }
  }

  /// 發送配對通知給雙方
  ///
  /// [user1Id] 用戶 A ID
  /// [user2Id] 用戶 B ID
  /// [chatRoomId] 聊天室 ID
  Future<void> sendMatchNotification({
    required String user1Id,
    required String user2Id,
    required String chatRoomId,
  }) async {
    try {
      debugPrint('Sending match notification for $user1Id and $user2Id');

      // 調用 Cloud Function 發送通知
      // 我們發送兩次，或者讓 Cloud Function 處理。
      // 根據需求 "call notification_service to send push to both parties"，
      // 我們在這裡封裝調用邏輯。

      // 通知 User 1
      await _sendSingleNotification(
        targetUserId: user1Id,
        type: 'match',
        title: '配對成功！',
        body: '你和一個新朋友配對成功了，快來打招呼吧！',
        data: {
          'chatRoomId': chatRoomId,
          'partnerId': user2Id,
          'actionType': 'open_chat', // 用於客戶端導航
        },
      );

      // 通知 User 2
      await _sendSingleNotification(
        targetUserId: user2Id,
        type: 'match',
        title: '配對成功！',
        body: '你和一個新朋友配對成功了，快來打招呼吧！',
        data: {
          'chatRoomId': chatRoomId,
          'partnerId': user1Id,
          'actionType': 'open_chat',
        },
      );

    } catch (e) {
      debugPrint('Failed to send match notifications: $e');
      // 不拋出異常，以免中斷配對流程
    }
  }

  /// 內部方法：調用 Cloud Function
  Future<void> _sendSingleNotification({
    required String targetUserId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'userId': targetUserId,
        'type': type,
        'title': title,
        'message': body,
        'data': data,
      });
    } catch (e) {
      debugPrint('Error calling sendNotification Cloud Function for $targetUserId: $e');
    }
  }
}
