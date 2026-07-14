import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

/// Service for managing notification storage in Firestore.
/// Handles saving, retrieving, and updating notification status.
class NotificationStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Save a notification to Firestore.
  ///
  /// If [notification.id] is not empty, uses [set] to update/create the document
  /// with that specific ID. This is useful when syncing with external IDs (e.g., FCM message IDs).
  ///
  /// If [notification.id] is empty, uses [add] to create a new document with an auto-generated ID.
  ///
  /// Returns the document ID.
  Future<String> saveNotification(NotificationModel notification) async {
    try {
      if (notification.id.isNotEmpty) {
        await _notificationsCollection
            .doc(notification.id)
            .set(notification.toMap(), SetOptions(merge: true));
        return notification.id;
      } else {
        // If ID is empty, we exclude it from the map if it was included (though toMap doesn't include ID usually)
        // NotificationModel.toMap() does NOT include 'id'.
        final docRef = await _notificationsCollection.add(notification.toMap());
        return docRef.id;
      }
    } catch (e) {
      debugPrint('Error saving notification: $e');
      rethrow;
    }
  }

  /// Get notifications for a user with pagination.
  ///
  /// [userId] The ID of the user to fetch notifications for.
  /// [lastDocument] The last document from the previous page (for pagination).
  /// [limit] The maximum number of notifications to return (default: 20).
  ///
  /// Returns a Map containing:
  /// - 'notifications': List<NotificationModel>
  /// - 'lastDocument': DocumentSnapshot (or null)
  /// - 'hasMore': bool
  Future<Map<String, dynamic>> getNotifications({
    required String userId,
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
    try {
      Query query = _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final QuerySnapshot snapshot = await query.get();

      final List<NotificationModel> notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      return {
        'notifications': notifications,
        'lastDocument': snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        'hasMore': snapshot.docs.length == limit,
      };
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      rethrow;
    }
  }

  /// Mark a single notification as read.
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

  /// Mark all unread notifications as read for a user.
  /// Uses batch writes to handle multiple updates efficiently.
  Future<void> markAllAsRead(String userId) async {
    try {
      final QuerySnapshot unreadSnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadSnapshot.docs.isEmpty) return;

      WriteBatch batch = _firestore.batch();
      int batchCount = 0;
      const int batchLimit = 500;

      for (var doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
        batchCount++;

        if (batchCount == batchLimit) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Get the count of unread notifications for a user.
  /// Uses [count] aggregation query for efficiency.
  Future<int> getUnreadCount(String userId) async {
    try {
      final AggregateQuerySnapshot snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }
}
