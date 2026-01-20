import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  Future<void> sendMatchNotification(String user1Id, String user2Id) async {
    try {
      final callable = _functions.httpsCallable('sendMatchNotification');
      await callable.call({
        'user1Id': user1Id,
        'user2Id': user2Id,
      });
    } catch (e) {
      print('發送配對通知失敗: $e');
      // 不拋出異常，以免影響配對流程
    }
  }
}
