import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/notification_settings_model.dart';

class NotificationPreferencesService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Syncs the user's notification settings with Firebase Cloud Messaging topics.
  Future<void> syncSettings(NotificationSettings settings) async {
    try {
      if (!settings.pushEnabled) {
        // If master switch is off, unsubscribe from all optional topics
        await _messaging.unsubscribeFromTopic('marketing_promo');
        await _messaging.unsubscribeFromTopic('marketing_newsletter');
        return;
      }

      // Sync Marketing Promo
      if (settings.marketingPromo) {
        await _messaging.subscribeToTopic('marketing_promo');
      } else {
        await _messaging.unsubscribeFromTopic('marketing_promo');
      }

      // Sync Marketing Newsletter
      if (settings.marketingNewsletter) {
        await _messaging.subscribeToTopic('marketing_newsletter');
      } else {
        await _messaging.unsubscribeFromTopic('marketing_newsletter');
      }

      debugPrint('Notification settings synced with FCM topics');
    } catch (e) {
      debugPrint('Error syncing notification settings: $e');
    }
  }
}
