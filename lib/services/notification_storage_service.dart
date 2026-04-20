import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// Notification Storage Service
///
/// 負責將接收到的通知存儲到 Firestore 的 `notifications` 集合，
/// 並提供查詢、標記已讀等功能。
class NotificationStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'notifications';

  /// 儲存通知
  ///
  /// 將 [NotificationModel] 保存到 Firestore。
  /// 如果 [notification.id] 不為空，則使用該 ID 作為文檔 ID (set)。
  /// 如果 [notification.id] 為空，則會自動生成 ID (add)，但注意這樣會與傳入的 model ID 不一致。
  /// 通常建議在調用此方法前確保 model 有 ID，或者使用此方法後重新獲取 model。
  ///
  /// [notification] 要儲存的通知對象
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      if (notification.id.isNotEmpty) {
        await _firestore
            .collection(_collection)
            .doc(notification.id)
            .set(notification.toMap());
      } else {
        // 如果 ID 為空，我們使用 add，這會生成一個新 ID
        // 但 NotificationModel 是 immutable 的，所以這裡僅儲存數據
        // 實際應用中，建議在創建 model 時就分配 ID
        await _firestore.collection(_collection).add(notification.toMap());
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
      rethrow;
    }
  }

  /// 獲取用戶的通知列表 (Stream)
  ///
  /// 返回一個 [Stream]，當 Firestore 中的數據發生變化時會發出新的列表。
  ///
  /// [userId] 用戶 ID
  /// [limit] 返回的最大通知數量，預設為 20
  Stream<List<NotificationModel>> getNotificationsStream(String userId,
      {int limit = 20}) {
    return _firestore
        .collection(_collection)
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

  /// 獲取用戶的通知列表 (Future, 分頁支持)
  ///
  /// 用於一次性獲取通知列表，支持分頁加載。
  ///
  /// [userId] 用戶 ID
  /// [limit] 每次獲取的數量，預設為 20
  /// [lastDocument] 上一頁的最後一個文檔快照，用於獲取下一頁數據
  Future<List<NotificationModel>> getNotifications(String userId,
      {int limit = 20, DocumentSnapshot? lastDocument}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      rethrow;
    }
  }

  /// 標記單個通知為已讀
  ///
  /// [notificationId] 通知的文檔 ID
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection(_collection).doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// 標記用戶的所有通知為已讀
  ///
  /// [userId] 用戶 ID
  Future<void> markAllAsRead(String userId) async {
    try {
      // 由於 Firestore 不支持直接的 update where query，
      // 我們需要先查詢所有未讀通知，然後使用 Batch 寫入。
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// 獲取未讀通知數量 (Stream)
  ///
  /// 實時監聽用戶的未讀通知數量。
  /// 注意：對於大量數據，頻繁讀取可能會增加成本。
  ///
  /// [userId] 用戶 ID
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
