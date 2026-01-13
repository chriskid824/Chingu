import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// 通知存儲服務 - 負責 Firestore 中的通知數據持久化
class NotificationStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// 保存通知
  Future<String> saveNotification(NotificationModel notification) async {
    try {
      if (notification.id.isNotEmpty) {
        await _notificationsCollection
            .doc(notification.id)
            .set(notification.toMap(), SetOptions(merge: true));
        return notification.id;
      } else {
        final docRef = await _notificationsCollection.add(notification.toMap());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
      rethrow;
    }
  }

  /// 獲取通知列表（分頁）
  ///
  /// [userId] 用戶 ID
  /// [limit] 每頁數量
  /// [lastDocument] 上一頁的最後一個文檔（用於分頁）
  /// [type] 可選的過濾類型 ('match', 'event', 'system', 'message', etc.)
  /// 返回 Map: {'notifications': List<NotificationModel>, 'lastDocument': DocumentSnapshot?, 'hasMore': bool}
  Future<Map<String, dynamic>> getNotifications(
    String userId, {
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? type,
  }) async {
    try {
      Query query = _notificationsCollection
          .where('userId', isEqualTo: userId);

      // 如果有指定類型，添加過濾條件
      if (type != null) {
          if (type == 'system') {
              // 系統類型可能包含 rating 和 system
              query = query.where('type', whereIn: ['system', 'rating']);
          } else {
              query = query.where('type', isEqualTo: type);
          }
      }

      // 注意：使用多個字段過濾和排序需要複合索引
      // userId + type + createdAt DESC
      // userId + createdAt DESC
      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final querySnapshot = await query.get();
      final docs = querySnapshot.docs;

      final notifications = docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      return {
        'notifications': notifications,
        'lastDocument': docs.isNotEmpty ? docs.last : null,
        'hasMore': docs.length == limit,
      };
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      rethrow;
    }
  }

  /// 標記通知為已讀
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// 獲取未讀通知數量
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error counting unread notifications: $e');
      return 0;
    }
  }
}
