import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a match notification to both the current user and the target user.
  ///
  /// [otherUserId] is the ID of the user who was just matched with.
  Future<void> sendMatchNotification(String otherUserId) async {
    try {
      final callable = _functions.httpsCallable('sendMatchNotification');
      await callable.call(<String, dynamic>{
        'otherUserId': otherUserId,
      });
      print('Match notification sent successfully to $otherUserId and self.');
    } catch (e) {
      print('Failed to send match notification: $e');
      // We do not rethrow because notification failure shouldn't block the match flow
    }
  }
}
