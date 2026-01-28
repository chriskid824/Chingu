import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class NotificationStorageService {
  static final NotificationStorageService _instance = NotificationStorageService._internal();

  factory NotificationStorageService() {
    return _instance;
  }

  NotificationStorageService._internal();

  FirebaseFirestore? _firestoreOverride;
  FirebaseAuth? _authOverride;

  @visibleForTesting
  set firestoreInstance(FirebaseFirestore firestore) {
    _firestoreOverride = firestore;
  }

  @visibleForTesting
  set authInstance(FirebaseAuth auth) {
    _authOverride = auth;
  }

  FirebaseFirestore get _firestore => _firestoreOverride ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  CollectionReference get _notificationsCollection => _firestore.collection('notifications');
  CollectionReference get _usersCollection => _firestore.collection('users');

  String? get _currentUserId => _auth.currentUser?.uid;

  /// 儲存通知
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final userId = notification.userId;
      if (userId.isEmpty) {
        debugPrint('NotificationStorageService: userId is empty, cannot save.');
        return;
      }

      // 檢查用戶設定
      if (!await _shouldSaveNotification(userId, notification)) {
        debugPrint('NotificationStorageService: Notification skipped due to user settings.');
        return;
      }

      await _notificationsCollection.add(notification.toMap());
    } catch (e) {
      debugPrint('NotificationStorageService: Error saving notification: $e');
      rethrow;
    }
  }

  /// 檢查是否應該儲存通知
  Future<bool> _shouldSaveNotification(String userId, NotificationModel notification) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return true; // 如果找不到用戶，默認儲存

      final user = UserModel.fromFirestore(doc);
      final settings = user.notificationSettings;

      switch (notification.type) {
        case 'match':
          return settings.newMatch;
        case 'message':
          return settings.newMessage;
        case 'event':
          return settings.eventUpdate; // 假設 event 對應 eventUpdate
        case 'system':
          return settings.systemUpdate;
        default:
          return true;
      }
    } catch (e) {
      debugPrint('NotificationStorageService: Error checking settings: $e');
      return true; // 發生錯誤時默認儲存
    }
  }

  /// 獲取通知流
  Stream<List<NotificationModel>> getNotificationsStream({int limit = 20}) {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value([]);
    }

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

  /// 標記通知為已讀
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('NotificationStorageService: Error marking as read: $e');
      rethrow;
    }
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('NotificationStorageService: Error marking all as read: $e');
      rethrow;
    }
  }

  /// 獲取未讀通知數量流
  Stream<int> getUnreadCountStream() {
    final userId = _currentUserId;
    if (userId == null) {
      return Stream.value(0);
    }

    // 注意：Firestore 的 count() 聚合查詢是比較新的功能，或者直接查詢並計算文檔數
    // 為了實時更新，這裡使用 snapshots
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
