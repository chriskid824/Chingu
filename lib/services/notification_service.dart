import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// 通知服務 - 負責發送遠端推送通知
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  // 依賴注入 (用於測試)
  FirebaseFirestore? _firestoreOverride;
  FirebaseFunctions? _functionsOverride;

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseFunctions get _functions => _functionsOverride ?? FirebaseFunctions.instance;

  @visibleForTesting
  void setDependencies({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    _firestoreOverride = firestore;
    _functionsOverride = functions;
  }

  /// 發送配對成功通知
  ///
  /// [fromUserId] 發起配對/操作的用戶 ID (例如剛剛滑動喜歡的人)
  /// [toUserId] 接收通知的目標用戶 ID
  /// [fromUserName] 發起/對方用戶名稱 (顯示在通知中)
  Future<void> sendMatchNotification({
    required String fromUserId,
    required String toUserId,
    required String fromUserName,
  }) async {
    try {
      print('準備發送配對通知給 $toUserId (來自 $fromUserName)');

      final token = await _getFcmToken(toUserId);
      if (token == null || token.isEmpty) {
        print('找不到用戶 $toUserId 的 FCM Token，跳過發送通知');
        return;
      }

      final callable = _functions.httpsCallable('sendNotification');

      await callable.call({
        'token': token,
        'title': '新配對成功! 🎉',
        'body': '你與 $fromUserName 配對成功了！快去打個招呼吧',
        'imageUrl': null, // 可以添加用戶頭像 URL
        'data': {
          'actionType': 'open_chat',
          'actionData': fromUserId, // 點擊導航到與此人的聊天
          'type': 'match',
        },
      });

      print('成功發送配對通知給 $toUserId');
    } catch (e) {
      print('發送配對通知失敗: $e');
      // 不拋出異常，以免影響配對流程
    }
  }

  /// 獲取用戶 FCM Token
  Future<String?> _getFcmToken(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('fcmToken')) {
          return data['fcmToken'] as String?;
        }
      }
      return null;
    } catch (e) {
      print('獲取 FCM Token 失敗: $e');
      return null;
    }
  }
}
