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

  /// 獲取當前用戶 ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 獲取用戶通知集合引用
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// 檢查是否應該發送通知
  Future<bool> _shouldNotify(String userId, bool Function(UserModel) preferenceSelector) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final user = UserModel.fromFirestore(doc);

      // 首先檢查總開關
      if (!user.pushNotificationsEnabled) return false;

      // 檢查特定偏好
      return preferenceSelector(user);
    } catch (e) {
      print('檢查通知偏好失敗: $e');
      return true; // 默認發送，避免因錯誤漏發
    }
  }

  /// 儲存新通知
  Future<String> saveNotification(NotificationModel notification) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await _notificationsRef(userId).add(notification.toMap());
    return docRef.id;
  }

  /// 批量儲存通知 (用於同步)
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final batch = _firestore.batch();
    for (final notification in notifications) {
      final docRef = _notificationsRef(userId).doc(notification.id);
      batch.set(docRef, notification.toMap());
    }
    await batch.commit();
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
    required String title,
    required String message,
    String? imageUrl,
    String? actionType,
    String? actionData,
  }) async {
    final userId = _currentUserId;
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

    await _notificationsRef(userId).add(notification.toMap());
  }

  /// 創建喜歡通知 (有人喜歡你)
  Future<void> createLikeNotification({
    required String targetUserId,
    required String admirerName,
    required String admirerId,
    String? admirerPhotoUrl,
  }) async {
    // 檢查偏好
    final shouldNotify = await _shouldNotify(targetUserId, (u) => u.notifyNewMatches);
    if (!shouldNotify) return;

    final notification = NotificationModel(
      id: '',
      userId: targetUserId,
      type: 'like',
      title: '有人喜歡你!',
      message: '$admirerName 喜歡了你！',
      imageUrl: admirerPhotoUrl,
      actionType: 'view_profile',
      actionData: admirerId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(targetUserId).add(notification.toMap());
  }

  /// 創建配對通知
  Future<void> createMatchNotification({
    required String targetUserId,
    required String matchedUserName,
    required String matchedUserId,
    String? matchedUserPhotoUrl,
  }) async {
    // 檢查偏好
    final shouldNotify = await _shouldNotify(targetUserId, (u) => u.notifyMatchSuccess);
    if (!shouldNotify) return;

    final notification = NotificationModel(
      id: '',
      userId: targetUserId,
      type: 'match',
      title: '新配對成功! 🎉',
      message: '你與 $matchedUserName 配對成功了！快去打個招呼吧',
      imageUrl: matchedUserPhotoUrl,
      actionType: 'open_chat',
      actionData: matchedUserId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(targetUserId).add(notification.toMap());
  }

  /// 創建活動通知
  Future<void> createEventNotification({
    required String targetUserId,
    required String eventId,
    required String eventTitle,
    required String message,
    String? imageUrl,
  }) async {
    // 檢查偏好
    final shouldNotify = await _shouldNotify(targetUserId, (u) => u.notifyEventReminders);
    if (!shouldNotify) return;

    final notification = NotificationModel(
      id: '',
      userId: targetUserId,
      type: 'event',
      title: eventTitle,
      message: message,
      imageUrl: imageUrl,
      actionType: 'view_event',
      actionData: eventId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(targetUserId).add(notification.toMap());
  }

  /// 創建消息通知
  Future<void> createMessageNotification({
    required String targetUserId,
    required String senderName,
    required String senderId,
    required String messagePreview,
    String? senderPhotoUrl,
  }) async {
    // 檢查偏好
    final shouldNotify = await _shouldNotify(targetUserId, (u) => u.notifyNewMessages);
    if (!shouldNotify) return;

    final notification = NotificationModel(
      id: '',
      userId: targetUserId,
      type: 'message',
      title: senderName,
      message: messagePreview,
      imageUrl: senderPhotoUrl,
      actionType: 'open_chat',
      actionData: senderId,
      isRead: false,
      createdAt: DateTime.now(),
    );

    await _notificationsRef(targetUserId).add(notification.toMap());
  }
}
