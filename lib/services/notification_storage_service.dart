import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationStorageService {
  final FirebaseFirestore _firestore;

  NotificationStorageService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Saves a notification to Firestore.
  /// If the notification ID is empty, a new document ID will be generated.
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      DocumentReference docRef;
      if (notification.id.isEmpty) {
        docRef = _notificationsCollection.doc();
      } else {
        docRef = _notificationsCollection.doc(notification.id);
      }

      await docRef.set(notification.toMap());
    } catch (e) {
      throw Exception('Failed to save notification: $e');
    }
  }

  /// Gets a stream of notifications for a specific user.
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  /// Marks all notifications for a user as read.
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  /// Gets the count of unread notifications for a user.
  Stream<int> getUnreadCountStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Gets the count of unread notifications for a user (Future).
  Future<int> getUnreadCount(String userId) async {
    try {
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return querySnapshot.count ?? 0;
    } catch (e) {
      // Fallback if count() fails
      final querySnapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return querySnapshot.size;
    }
  }

  /// Deletes a notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
