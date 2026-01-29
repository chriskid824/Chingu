import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  /// Sends a push notification via Cloud Functions
  Future<void> sendNotification({
    required String recipientId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('sendNotification');
      await callable.call({
        'recipientId': recipientId,
        'title': title,
        'body': body,
        'data': data,
      });
      debugPrint('Notification sent to $recipientId');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      // Swallow error to prevent blocking main flow
    }
  }
}
