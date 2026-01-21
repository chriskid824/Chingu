import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  /// [chatRoomId] 聊天室 ID
  Future<void> sendMatchNotification({
    required String user1Id,
    required String user2Id,
    required String chatRoomId,
  }) async {
    try {
      await _functions.httpsCallable('notifyMatch').call({
        'user1Id': user1Id,
        'user2Id': user2Id,
        'chatRoomId': chatRoomId,
      });
    } catch (e) {
      // 不拋出錯誤，避免影響配對流程
      print('Error sending match notification: $e');
    }
  }
}
