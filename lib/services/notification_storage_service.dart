import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';

/// 通知儲存服務
/// 負責 Firestore 中通知的 CRUD 操作
class NotificationStorageService {
  // Singleton pattern
  static final NotificationStorageService _instance =
      NotificationStorageService._internal();

  factory NotificationStorageService() => _instance;

  NotificationStorageService._internal();

  // Lazy initialization for testability
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  @visibleForTesting
  set firestoreInstance(FirebaseFirestore instance) =>
      _firestoreInstance = instance;

  @visibleForTesting
  set authInstance(FirebaseAuth instance) => _authInstance = instance;

  /// 獲取當前用戶 ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 獲取用戶通知集合引用
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// 檢查是否應該發送通知 (根據用戶偏好)
  Future<bool> _shouldSendNotification(String userId, String type) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final user = UserModel.fromFirestore(doc);
      final settings = user.notificationSettings;

      if (!settings.pushEnabled) return false;

      switch (type) {
        case 'match':
          // 這裡統稱 match，具體細分可能需要更細的 type 或檢查內容
          // 暫時同時檢查 newMatch 和 matchSuccess，只要有一個開啟就允許
          // 未來可以細分 type 為 'match_new' 和 'match_success'
          return settings.matchSuccess || settings.newMatch;
        case 'message':
          return settings.newMessage;
        case 'event':
          return settings.eventReminder || settings.eventChange;
        case 'marketing':
          return settings.marketingPromotion || settings.marketingNewsletter;
        case 'system':
          return true;
        default:
          return true;
      }
    } catch (e) {
      print('Error checking notification settings: $e');
      // 發生錯誤時預設允許發送，避免重要通知遺失
      return true;
    }
  }

  /// 儲存新通知
  Future<String> saveNotification(NotificationModel notification) async {
    final userId = notification.userId;
    if (userId.isEmpty) {
      throw Exception('Notification userId is required');
    }

    // 檢查用戶偏好
    if (!await _shouldSendNotification(userId, notification.type)) {
      return ''; // 用戶已關閉此類通知
    }

    final docRef = await _notificationsRef(userId).add(notification.toMap());
    return docRef.id;
  }

  /// 批量儲存通知 (用於同步)
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    if (notifications.isEmpty) return;

    // 假設同一批通知通常屬於同一個用戶，或者混合
    // 為了安全起見，我們逐個檢查或分組檢查
    // 這裡簡單實現為逐個檢查並添加到 batch

    final batch = _firestore.batch();
    bool hasUpdates = false;

    for (final notification in notifications) {
      if (notification.userId.isEmpty) continue;

      // 這裡如果逐個 await _shouldSendNotification 會有效能問題
      // 但考慮到批量通常不大，暫時接受
      // 優化：可以先 fetch user settings cached
      if (await _shouldSendNotification(notification.userId, notification.type)) {
        final docRef = _notificationsRef(notification.userId).doc(notification.id.isEmpty ? null : notification.id);
        batch.set(docRef, notification.toMap());
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }

  /// 獲取所有通知 (分頁)
  Future<List<NotificationModel>> getNotifications({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    Query<Map<String, dynamic>> query = _notificationsRef(userId)
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

  /// 獲取未讀通知
  Future<List<NotificationModel>> getUnreadNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final snapshot = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  /// 獲取未讀通知數量
  Future<int> getUnreadCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final snapshot = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// 標記單個通知為已讀
  Future<void> markAsRead(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _notificationsRef(userId).doc(notificationId).update({
      'isRead': true,
    });
  }

  /// 標記所有通知為已讀
  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final unread = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// 刪除單個通知
  Future<void> deleteNotification(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _notificationsRef(userId).doc(notificationId).delete();
  }

  /// 刪除所有通知
  Future<void> deleteAllNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final snapshot = await _notificationsRef(userId).get();
    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// 刪除舊通知 (超過指定天數)
  Future<int> deleteOldNotifications({int olderThanDays = 30}) async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final snapshot = await _notificationsRef(userId)
        .where('createdAt', isLessThan: cutoffTimestamp)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return snapshot.docs.length;
  }

  /// 監聽通知變化 (實時更新)
  Stream<List<NotificationModel>> watchNotifications({int limit = 50}) {
    final userId = _currentUserId;
    if (userId == null) return Stream.value([]);

    return _notificationsRef(userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// 監聽未讀通知數量
  Stream<int> watchUnreadCount() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);

    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 按類型獲取通知
  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final snapshot = await _notificationsRef(userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  /// 創建系統通知
  Future<void> createSystemNotification({
    String? targetUserId,
    required String title,
    required String message,
    String? imageUrl,
    String? actionType,
    String? actionData,
  }) async {
    final userId = targetUserId ?? _currentUserId;
    if (userId == null) return;

    final notification = NotificationModel(
      id: '', // Will be set by Firestore
      userId: userId,
      type: 'system',
      title: title,
      message: message,
      imageUrl: imageUrl,
      actionType: actionType,
      actionData: actionData,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await saveNotification(notification);
  }

  /// 創建配對通知
  Future<void> createMatchNotification({
    String? targetUserId,
    required String matchedUserName,
    required String matchedUserId,
    String? matchedUserPhotoUrl,
  }) async {
    final userId = targetUserId ?? _currentUserId;
    if (userId == null) return;

    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'match',
      title: '新配對成功! 🎉',
      message: '你與 $matchedUserName 配對成功了！快去打個招呼吧',
      imageUrl: matchedUserPhotoUrl,
      actionType: 'open_chat',
      actionData: matchedUserId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await saveNotification(notification);
  }

  /// 創建活動通知
  Future<void> createEventNotification({
    String? targetUserId,
    required String eventId,
    required String eventTitle,
    required String message,
    String? imageUrl,
  }) async {
    final userId = targetUserId ?? _currentUserId;
    if (userId == null) return;

    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'event',
      title: eventTitle,
      message: message,
      imageUrl: imageUrl,
      actionType: 'view_event',
      actionData: eventId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await saveNotification(notification);
  }

  /// 創建消息通知
  Future<void> createMessageNotification({
    String? targetUserId,
    required String senderName,
    required String senderId,
    required String messagePreview,
    String? senderPhotoUrl,
  }) async {
    final userId = targetUserId ?? _currentUserId;
    if (userId == null) return;

    final notification = NotificationModel(
      id: '',
      userId: userId,
      type: 'message',
      title: senderName,
      message: messagePreview,
      imageUrl: senderPhotoUrl,
      actionType: 'open_chat',
      actionData: senderId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await saveNotification(notification);
  }
}
