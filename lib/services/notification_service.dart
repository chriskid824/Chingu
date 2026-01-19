import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// 發送配對成功通知
  ///
  /// [userId] 接收通知的用戶 ID
  /// [partnerName] 配對對象的名稱
  /// [chatRoomId] (可選) 聊天室 ID，用於點擊導航
  Future<void> sendMatchNotification({
    required String userId,
    required String partnerName,
    String? chatRoomId,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'userId': userId,
        'title': '配對成功！',
        'body': '你與 $partnerName 配對成功，快來打招呼吧！',
        'data': {
          'actionType': 'open_chat',
          'actionData': chatRoomId ?? '', // 傳遞聊天室 ID
          'type': 'match_success',
        },
      });
    } catch (e) {
      // 這裡我們只記錄錯誤，不拋出異常，以免影響配對流程
      print('發送配對通知失敗: $e');
    }
  }

  /// 通用發送通知方法
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
        'imageUrl': imageUrl,
      });
    } catch (e) {
      print('發送通知失敗: $e');
      throw e;
    }
  }
}
