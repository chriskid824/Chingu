import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

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

  /// 設置測試用的實例
  void setInstancesForTesting({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    _firestoreInstance = firestore;
    _authInstance = auth;
  }

  /// 獲取當前用戶 ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// 獲取用戶通知集合引用
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// 儲存新通知
  Future<String> saveNotification(NotificationModel notification) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // 確保通知屬於當前用戶，或者通知中的 userId 與當前用戶匹配
    // 如果通知對象是別人，這裡需要小心。通常 StorageService 用於存儲 *接收到* 的通知，
    // 所以應該存到 _currentUserId 的集合中。
    // 但是 NotificationModel 有 userId 字段。
    // 我們假設 saveNotification 是在當前用戶收到通知時調用，存入自己的收件箱。

    if (notification.id.isNotEmpty) {
      // 如果有 ID (例如來自 FCM messageId)，使用它作為文檔 ID 以防止重複
      await _notificationsRef(userId).doc(notification.id).set(notification.toMap());
      return notification.id;
    } else {
      final docRef = await _notificationsRef(userId).add(notification.toMap());
      return docRef.id;
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

  /// 監聽未讀通知數量
  Stream<int> watchUnreadCount() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);

    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
