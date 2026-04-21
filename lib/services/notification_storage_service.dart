import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

/// 通知儲存服務 - 負責將通知存到 Firestore 並管理讀取狀態
class NotificationStorageService {
  final FirebaseFirestore _firestore;

  NotificationStorageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// 儲存通知
  Future<void> saveNotification(NotificationModel notification) async {
    await _notificationsCollection
        .doc(notification.id)
        .set(notification.toMap());
  }

  /// 獲取通知流
  Stream<List<NotificationModel>> getNotificationsStream(String userId,
      {int limit = 20}) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// 獲取通知列表（支持分頁）
  Future<List<NotificationModel>> getNotifications(String userId,
      {int limit = 20, DocumentSnapshot? startAfter}) async {
    Query query = _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  /// 標記通知為已讀
  Future<void> markAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead(String userId) async {
    // 查詢該用戶所有未讀通知
    final querySnapshot = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (querySnapshot.docs.isEmpty) return;

    // Firestore 批量寫入限制為 500 次操作
    final int batchSize = 500;
    List<DocumentSnapshot> allDocs = querySnapshot.docs;

    for (int i = 0; i < allDocs.length; i += batchSize) {
        var batch = _firestore.batch();
        var end = (i + batchSize < allDocs.length) ? i + batchSize : allDocs.length;
        var subList = allDocs.sublist(i, end);

        for (var doc in subList) {
           batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
    }
  }

  /// 獲取未讀通知數量流
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
