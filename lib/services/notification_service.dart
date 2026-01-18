import 'package:cloud_functions/cloud_functions.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a match success notification to the target user.
  ///
  /// [targetUserId] is the ID of the user to receive the notification.
  /// [partnerName] is the name of the matched partner (to be shown in the notification).
  Future<void> sendMatchNotification({
    required String targetUserId,
    required String partnerName,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendNotification');
      await callable.call({
        'targetUserId': targetUserId,
        'notificationType': 'match_success',
        'params': {
          'userName': partnerName,
        },
      });
    } catch (e) {
      // Log error but don't crash app
      print('Error sending match notification: $e');
    }
  }
}
