import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// NotificationStorageService
///
/// This service handles the persistence of notifications in Firestore.
/// It supports creating, reading (querying), updating (marking as read),
/// and deleting notifications.
///
/// It interacts with the `users/{userId}/notifications` collection.
class NotificationStorageService {
  // Singleton instance
  static final NotificationStorageService _instance =
      NotificationStorageService._internal();

  /// Factory constructor to return the singleton instance.
  factory NotificationStorageService() => _instance;

  NotificationStorageService._internal();

  // Lazy initialization for testability.
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  /// Sets mock instances for Firestore and FirebaseAuth.
  /// This method should only be used in tests.
  @visibleForTesting
  void setMockInstances({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) {
    _firestoreInstance = firestore;
    _authInstance = auth;
  }

  /// Gets the current authenticated user's ID.
  /// Returns null if no user is logged in.
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Returns a reference to the notifications collection for a specific user.
  CollectionReference<Map<String, dynamic>> _notificationsRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  /// Saves a single notification to Firestore.
  ///
  /// Returns the document ID of the saved notification.
  /// Throws an exception if the user is not authenticated.
  Future<String> saveNotification(NotificationModel notification) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Convert the model to a map and add it to the collection
    final docRef = await _notificationsRef(userId).add(notification.toMap());
    return docRef.id;
  }

  /// Saves multiple notifications in a batch operation.
  ///
  /// Useful for syncing or bulk updates.
  /// Handles batch limits (500 ops) and empty IDs.
  Future<void> saveNotifications(List<NotificationModel> notifications) async {
    final userId = _currentUserId;
    if (userId == null) return;
    if (notifications.isEmpty) return;

    // Process in chunks of 500 to respect Firestore batch limits
    for (var i = 0; i < notifications.length; i += 500) {
      final end = (i + 500 < notifications.length) ? i + 500 : notifications.length;
      final chunk = notifications.sublist(i, end);
      final batch = _firestore.batch();

      for (final notification in chunk) {
        DocumentReference docRef;
        if (notification.id.isNotEmpty) {
          docRef = _notificationsRef(userId).doc(notification.id);
        } else {
          // If ID is empty, generate a new document reference
          docRef = _notificationsRef(userId).doc();
        }
        batch.set(docRef, notification.toMap());
      }
      await batch.commit();
    }
  }

  /// Retrieves notifications for the current user with pagination.
  ///
  /// [limit] defaults to 20.
  /// [startAfter] can be used for pagination.
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

  /// Retrieves all unread notifications.
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

  /// Gets the count of unread notifications.
  Future<int> getUnreadCount() async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final snapshot = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _notificationsRef(userId).doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Marks all unread notifications as read.
  ///
  /// Handles batch limits (500 ops).
  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final unread = await _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    // Process in chunks of 500
    final docs = unread.docs;
    for (var i = 0; i < docs.length; i += 500) {
      final end = (i + 500 < docs.length) ? i + 500 : docs.length;
      final chunk = docs.sublist(i, end);
      final batch = _firestore.batch();

      for (final doc in chunk) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  /// Deletes a specific notification.
  Future<void> deleteNotification(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await _notificationsRef(userId).doc(notificationId).delete();
  }

  /// Deletes all notifications for the current user.
  ///
  /// Use with caution. Handles batch limits.
  Future<void> deleteAllNotifications() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final snapshot = await _notificationsRef(userId).get();
    if (snapshot.docs.isEmpty) return;

    final docs = snapshot.docs;
    for (var i = 0; i < docs.length; i += 500) {
      final end = (i + 500 < docs.length) ? i + 500 : docs.length;
      final chunk = docs.sublist(i, end);
      final batch = _firestore.batch();

      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Deletes notifications older than a specified number of days.
  ///
  /// Default is 30 days. Returns the number of deleted notifications.
  /// Handles batch limits.
  Future<int> deleteOldNotifications({int olderThanDays = 30}) async {
    final userId = _currentUserId;
    if (userId == null) return 0;

    final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
    final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

    final snapshot = await _notificationsRef(userId)
        .where('createdAt', isLessThan: cutoffTimestamp)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    final docs = snapshot.docs;
    for (var i = 0; i < docs.length; i += 500) {
      final end = (i + 500 < docs.length) ? i + 500 : docs.length;
      final chunk = docs.sublist(i, end);
      final batch = _firestore.batch();

      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    return docs.length;
  }

  /// Returns a stream of notifications for real-time updates.
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

  /// Returns a stream of the unread notification count.
  Stream<int> watchUnreadCount() {
    final userId = _currentUserId;
    if (userId == null) return Stream.value(0);

    return _notificationsRef(userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Retrieves notifications filtered by type.
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

  // --- Helper methods to create specific notification types ---

  /// Creates a system notification.
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
      id: '', // Firestore will generate the ID
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

  /// Creates a match notification.
  Future<void> createMatchNotification({
    required String matchedUserName,
    required String matchedUserId,
    String? matchedUserPhotoUrl,
  }) async {
    final userId = _currentUserId;
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

    await _notificationsRef(userId).add(notification.toMap());
  }

  /// Creates an event notification.
  Future<void> createEventNotification({
    required String eventId,
    required String eventTitle,
    required String message,
    String? imageUrl,
  }) async {
    final userId = _currentUserId;
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

    await _notificationsRef(userId).add(notification.toMap());
  }

  /// Creates a message notification.
  Future<void> createMessageNotification({
    required String senderName,
    required String senderId,
    required String messagePreview,
    String? senderPhotoUrl,
  }) async {
    final userId = _currentUserId;
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

    await _notificationsRef(userId).add(notification.toMap());
  }
}
