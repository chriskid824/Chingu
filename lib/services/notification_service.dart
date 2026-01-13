import 'package:cloud_functions/cloud_functions.dart';

/// 通知服務 - 負責與 Firebase Cloud Functions 交互發送通知
class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  ///
  /// 調用 Cloud Function `sendMatchNotification` 發送通知給雙方
  Future<void> sendMatchNotification(String user1Id, String user2Id) async {
    try {
      await _functions.httpsCallable('sendMatchNotification').call({
        'user1Id': user1Id,
        'user2Id': user2Id,
      });
    } catch (e) {
      throw Exception('發送配對通知失敗: $e');
    }
  }
}
