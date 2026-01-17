import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  /// [chatRoomId] 聊天室 ID
  Future<void> sendMatchNotification(String user1Id, String user2Id, String chatRoomId) async {
    try {
      final callable = _functions.httpsCallable('notifyMatch');
      await callable.call({
        'user1Id': user1Id,
        'user2Id': user2Id,
        'chatRoomId': chatRoomId,
      });
      debugPrint('配對通知發送請求已送出');
    } catch (e) {
      debugPrint('發送配對通知失敗: $e');
      // 不拋出異常以免影響主流程
    }
  }
}
