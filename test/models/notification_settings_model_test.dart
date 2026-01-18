import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('NotificationSettingsModel', () {
    test('default values should be correct', () {
      const settings = NotificationSettingsModel();
      expect(settings.pushEnabled, true);
      expect(settings.newMatch, true);
      expect(settings.matchSuccess, true);
      expect(settings.newMessage, true);
      expect(settings.showMessagePreview, true);
      expect(settings.eventReminder, true);
      expect(settings.eventChanges, true);
      expect(settings.marketingPromotion, false);
      expect(settings.marketingNewsletter, false);
    });

    test('toMap and fromMap should work correctly', () {
      final settings = NotificationSettingsModel(
        pushEnabled: false,
        newMatch: false,
        matchSuccess: false,
        newMessage: false,
        showMessagePreview: false,
        eventReminder: false,
        eventChanges: false,
        marketingPromotion: true,
        marketingNewsletter: true,
      );

      final map = settings.toMap();
      final newSettings = NotificationSettingsModel.fromMap(map);

      expect(newSettings.pushEnabled, false);
      expect(newSettings.newMatch, false);
      expect(newSettings.matchSuccess, false);
      expect(newSettings.newMessage, false);
      expect(newSettings.showMessagePreview, false);
      expect(newSettings.eventReminder, false);
      expect(newSettings.eventChanges, false);
      expect(newSettings.marketingPromotion, true);
      expect(newSettings.marketingNewsletter, true);
    });

    test('copyWith should work correctly', () {
      const settings = NotificationSettingsModel();
      final newSettings = settings.copyWith(pushEnabled: false);

      expect(newSettings.pushEnabled, false);
      expect(newSettings.newMatch, true); // Should remain unchanged
    });
  });
}
