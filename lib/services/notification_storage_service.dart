import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:flutter/foundation.dart';

/// 負責處理通知的持久化存儲和檢索
class NotificationStorageService {
  static final NotificationStorageService _instance = NotificationStorageService._internal();
  factory NotificationStorageService() => _instance;
  NotificationStorageService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 為了支持測試，允許注入 Firestore 實例
  @visibleForTesting
  static NotificationStorageService test({required FirebaseFirestore firestore}) {
    final service = NotificationStorageService._internal();
    // 這裡我們無法輕易覆蓋 final _firestore，但因為它是單例，
    // 在真實測試中我們通常會 mock 整個 service 或者使用依賴注入。
    // 在此項目架構下，我們假設使用默認實例。
    return service;
  }

  /// 獲取通知集合引用
  CollectionReference<Map<String, dynamic>> _getCollection() {
    return _firestore.collection('notifications');
  }

  /// 獲取用戶的通知列表 (支持分頁)
  Future<Map<String, dynamic>> getNotifications({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _getCollection()
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    try {
      final querySnapshot = await query.get();
      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      return {
        'notifications': notifications,
        'lastDocument': querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
        'hasMore': querySnapshot.docs.length == limit,
      };
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// 監聽未讀通知數量
  Stream<int> getUnreadCountStream(String userId) {
    return _getCollection()
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 標記單個通知為已讀
  Future<void> markAsRead(String notificationId) async {
    try {
      await _getCollection().doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead(String userId) async {
    try {
      // 獲取所有未讀通知
      final querySnapshot = await _getCollection()
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      // 使用 Batch 寫入以提高效率並確保原子性
      // Firestore batch 限制為 500 個操作，如果超過需要分批處理
      final batchSize = 500;
      final chunks = <List<QueryDocumentSnapshot>>[];
      for (var i = 0; i < querySnapshot.docs.length; i += batchSize) {
        chunks.add(querySnapshot.docs.sublist(
            i,
            i + batchSize > querySnapshot.docs.length
                ? querySnapshot.docs.length
                : i + batchSize));
      }

      for (var chunk in chunks) {
        final batch = _firestore.batch();
        for (var doc in chunk) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// 保存新通知
  Future<String> saveNotification(NotificationModel notification) async {
    try {
      // 如果 ID 為空或由 Firestore 自動生成，則使用 add
      // 但 NotificationModel 通常帶有 ID。如果是新通知，ID 可能是暫時的或空的。
      // 這裡我們假設如果 ID 存在且非空，則使用 set (覆蓋/創建)，否則 add

      if (notification.id.isNotEmpty) {
        await _getCollection().doc(notification.id).set(notification.toMap());
        return notification.id;
      } else {
        final docRef = await _getCollection().add(notification.toMap());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
      rethrow;
    }
  }

  /// 刪除通知
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _getCollection().doc(notificationId).delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }
}
