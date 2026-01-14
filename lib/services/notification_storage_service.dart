import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Fetches a stream of notifications for a specific user.
  /// Ordered by creation date (newest first).
  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return NotificationModel.fromFirestore(doc);
      }).toList();
    });
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
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

  /// Deletes a specific notification.
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
