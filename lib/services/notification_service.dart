import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 發送通知
  Future<void> sendNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? imageUrl,
    String? actionType,
    String? actionData,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // ID 由 Firestore 生成
        userId: userId,
        type: type,
        title: title,
        message: message,
        imageUrl: imageUrl,
        actionType: actionType,
        actionData: actionData,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('notifications').add(notification.toMap());
    } catch (e) {
      // 記錄錯誤但不中斷流程，避免影響主邏輯
      print('發送通知失敗: $e');
    }
  }
}
