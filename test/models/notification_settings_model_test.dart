import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('NotificationSettings', () {
    test('defaults are correct', () {
      const settings = NotificationSettings();
      expect(settings.pushEnabled, true);
      expect(settings.marketingPromo, false);
      expect(settings.marketingNewsletter, false);
    });

    test('fromMap parses correctly', () {
      final map = {
        'pushEnabled': false,
        'newMatch': true,
        'marketingPromo': true,
      };
      final settings = NotificationSettings.fromMap(map);
      expect(settings.pushEnabled, false);
      expect(settings.newMatch, true);
      expect(settings.marketingPromo, true); // Overridden from default
      expect(settings.matchSuccess, true); // Default
    });

    test('toMap serializes correctly', () {
      const settings = NotificationSettings(
        pushEnabled: false,
        marketingPromo: true,
      );
      final map = settings.toMap();
      expect(map['pushEnabled'], false);
      expect(map['marketingPromo'], true);
      expect(map['newMatch'], true);
    });

    test('copyWith works correctly', () {
      const settings = NotificationSettings();
      final newSettings = settings.copyWith(pushEnabled: false);
      expect(newSettings.pushEnabled, false);
      expect(newSettings.marketingPromo, false); // Unchanged
    });
  });
}
