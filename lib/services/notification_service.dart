import 'package:cloud_functions/cloud_functions.dart';

/// 負責發送通知的服務 (調用 Cloud Functions)
class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// 發送配對成功通知
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  ///
  /// 調用 Cloud Function `sendMatchNotification` 發送推送給雙方
  Future<void> sendMatchNotification(String user1Id, String user2Id) async {
    try {
      print('正在調用 sendMatchNotification: user1=$user1Id, user2=$user2Id');
      final result = await _functions
          .httpsCallable('sendMatchNotification')
          .call({
        'user1Id': user1Id,
        'user2Id': user2Id,
      });
      print('配對通知發送結果: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('發送配對通知失敗 (Cloud Function Error): ${e.code} - ${e.message}');
      // 不拋出異常，以免中斷配對流程
    } catch (e) {
      print('發送配對通知失敗: $e');
    }
  }
}
