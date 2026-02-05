import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/notification_model.dart';

/// 通知服務 - 負責與 Firestore 交互以獲取和管理通知
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// 獲取分頁通知
  Future<Map<String, dynamic>> fetchNotifications({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

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
      throw Exception('Failed to fetch notifications');
    }
  }

  /// 標記單個通知為已讀
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead(String userId) async {
    try {
      // 由於 Firestore 不支持直接"更新所有匹配文檔"，我們需要先查詢未讀的
      // 如果未讀數量很大，應該分批處理。這裡假設數量合理或使用 Cloud Functions 更好。
      // 簡單起見，我們在客戶端分批處理 (batch limit 500)

      final unreadQuery = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .limit(500) // 限制一次最多處理 500 條
          .get();

      if (unreadQuery.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in unreadQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      // 如果還有更多，可能需要遞歸調用，但通常一次點擊清除500條足夠了
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// 監聽未讀通知數量
  Stream<int> streamUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
