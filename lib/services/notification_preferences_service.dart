import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/models/notification_settings_model.dart';
import 'package:chingu/services/firestore_service.dart';

class NotificationPreferencesService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Save settings to Firestore and sync topics
  ///
  /// [uid] User ID
  /// [settings] New settings to save
  /// [oldSettings] Previous settings (optional, will fetch from DB if null)
  Future<void> saveSettings(String uid, NotificationSettingsModel settings, {NotificationSettingsModel? oldSettings}) async {
    NotificationSettingsModel? effectiveOldSettings = oldSettings;

    // If oldSettings not provided, fetch current state from DB to calculate diff
    if (effectiveOldSettings == null) {
      try {
        final user = await _firestoreService.getUser(uid);
        effectiveOldSettings = user?.notificationSettings ?? const NotificationSettingsModel();
      } catch (e) {
        // If fetch fails, we assume default (all empty/false) so we might subscribe to things already subscribed.
        // FCM subscribe is idempotent so it's safe. Unsubscribe might be missed if we don't know we were subscribed.
        effectiveOldSettings = const NotificationSettingsModel();
      }
    }

    // 1. Sync topics (Subscribe/Unsubscribe based on diff)
    await _syncTopics(effectiveOldSettings, settings);

    // 2. Save to Firestore
    await _firestoreService.updateUser(uid, {
      'notificationSettings': settings.toMap(),
    });
  }

  Future<void> _syncTopics(NotificationSettingsModel oldSettings, NotificationSettingsModel newSettings) async {
    // Promo
    if (oldSettings.promo != newSettings.promo) {
      if (newSettings.promo) {
        await _messaging.subscribeToTopic('topic_promo');
      } else {
        await _messaging.unsubscribeFromTopic('topic_promo');
      }
    }

    // Newsletter
    if (oldSettings.newsletter != newSettings.newsletter) {
      if (newSettings.newsletter) {
        await _messaging.subscribeToTopic('topic_newsletter');
      } else {
        await _messaging.unsubscribeFromTopic('topic_newsletter');
      }
    }

    // Regions
    final oldRegions = Set<String>.from(oldSettings.subscribedRegions);
    final newRegions = Set<String>.from(newSettings.subscribedRegions);

    final addedRegions = newRegions.difference(oldRegions);
    final removedRegions = oldRegions.difference(newRegions);

    for (final region in addedRegions) {
      await _messaging.subscribeToTopic('region_${_sanitizeTopic(region)}');
    }
    for (final region in removedRegions) {
      await _messaging.unsubscribeFromTopic('region_${_sanitizeTopic(region)}');
    }

    // Interests
    final oldInterests = Set<String>.from(oldSettings.subscribedInterests);
    final newInterests = Set<String>.from(newSettings.subscribedInterests);

    final addedInterests = newInterests.difference(oldInterests);
    final removedInterests = oldInterests.difference(newInterests);

    for (final interest in addedInterests) {
      await _messaging.subscribeToTopic('interest_${_sanitizeTopic(interest)}');
    }
    for (final interest in removedInterests) {
      await _messaging.unsubscribeFromTopic('interest_${_sanitizeTopic(interest)}');
    }
  }

  /// Sanitize topic name to match [a-zA-Z0-9-_.~%]+
  String _sanitizeTopic(String topic) {
    // Use URI encoding to handle non-ASCII characters (e.g. Chinese)
    return Uri.encodeComponent(topic);
  }
}
