import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseFunctions _functions;

  NotificationService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  /// Sends a notification that a match has occurred.
  ///
  /// [targetUserId] is the ID of the user receiving the notification.
  /// [targetUserName] is the name of the *other* user (the one they matched with),
  /// which will be displayed in the notification body.
  Future<void> sendMatchNotification({
    required String targetUserId,
    required String targetUserName,
  }) async {
    try {
      await _functions.httpsCallable('sendNotification').call({
        'targetUserId': targetUserId,
        'notificationType': 'match_success',
        'params': {
          'userName': targetUserName,
        },
      });
      if (kDebugMode) {
        print('Match notification sent to $targetUserId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending match notification: $e');
      }
      // We do not rethrow because notification failure should not block the match flow.
    }
  }
}
