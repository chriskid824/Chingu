import 'package:cloud_functions/cloud_functions.dart';

/// Notification Service - Handles sending notifications via Cloud Functions
class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a match notification to both users
  ///
  /// [user1Id] ID of the first user
  /// [user2Id] ID of the second user
  /// [chatRoomId] ID of the chat room created for the match
  Future<void> sendMatchNotification(
      String user1Id, String user2Id, String chatRoomId) async {
    try {
      final callable = _functions.httpsCallable('sendMatchNotification');
      await callable.call({
        'user1Id': user1Id,
        'user2Id': user2Id,
        'chatRoomId': chatRoomId,
      });
      print('Match notification request sent for users $user1Id and $user2Id');
    } catch (e) {
      print('Failed to send match notification: $e');
      // We don't throw here to avoid interrupting the match flow,
      // as notification failure shouldn't stop the match creation.
    }
  }
}
