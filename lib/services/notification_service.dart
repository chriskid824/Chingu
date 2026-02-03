import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [currentUserId] 當前用戶 ID (主要用於客戶端邏輯，Cloud Function 會從 Context 獲取)
  /// [targetUserId] 對方用戶 ID
  /// [chatRoomId] 聊天室 ID
  Future<void> sendMatchNotification({
    required String currentUserId,
    required String targetUserId,
    required String chatRoomId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendMatchNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'chatRoomId': chatRoomId,
      });
    } catch (e) {
      // 記錄錯誤但不阻斷流程
      print('發送配對通知失敗: $e');
    }
  }
}
