import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// 通知服務 - 處理推送通知發送
class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對通知
  ///
  /// [targetUserId] 接收通知的用戶 ID
  /// [partnerName] 配對對象的名稱
  Future<void> sendMatchNotification({
    required String targetUserId,
    required String partnerName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'notificationType': 'match',
        'title': '配對成功！',
        'body': '你與 $partnerName 配對成功，快來聊天吧！',
        'data': {
          'type': 'match',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      });
    } catch (e) {
      debugPrint('發送通知失敗: $e');
      // 不拋出異常，以免影響主要流程
    }
  }
}
