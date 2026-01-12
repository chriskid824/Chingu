import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:flutter/foundation.dart';

/// 通知儲存服務
/// 負責將通知存到 Firestore notifications 集合，並支援查詢和標記已讀
class NotificationStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 獲取 notifications 集合的參考
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// 儲存通知
  ///
  /// 將接收到的通知存入 Firestore
  /// [notification] 通知的數據模型
  Future<String> saveNotification(NotificationModel notification) async {
    try {
      if (notification.id.isNotEmpty) {
        // 使用現有 ID (例如 FCM messageId)
        await _notificationsCollection
            .doc(notification.id)
            .set(notification.toMap());
        return notification.id;
      } else {
        // 自動生成 ID
        final docRef = await _notificationsCollection.add(notification.toMap());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
      throw Exception('Failed to save notification: $e');
    }
  }

  /// 獲取用戶的通知列表
  ///
  /// [userId] 用戶 ID
  /// [limit] 每次獲取的數量，預設 20
  /// [startAfter] 分頁遊標，上一頁最後一條通知的快照
  Future<Map<String, dynamic>> getNotifications(
    String userId, {
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();

      final notifications = querySnapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      return {
        'notifications': notifications,
        'lastDocument':
            querySnapshot.docs.isNotEmpty ? querySnapshot.docs.last : null,
        'hasMore': querySnapshot.docs.length == limit,
      };
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  /// 標記通知為已讀
  ///
  /// [notificationId] 通知 ID
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// 標記用戶所有通知為已讀
  ///
  /// [userId] 用戶 ID
  Future<void> markAllAsRead(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int count = 0;

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
        count++;

        if (count >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          count = 0;
        }
      }

      if (count > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// 獲取未讀通知數量
  ///
  /// [userId] 用戶 ID
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
