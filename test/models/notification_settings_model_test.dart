import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('NotificationSettings', () {
    test('should have correct default values', () {
      const settings = NotificationSettings();
      expect(settings.notifyPush, true);
      expect(settings.notifyNewMatch, true);
      expect(settings.notifyMatchSuccess, true);
      expect(settings.notifyNewMessage, true);
      expect(settings.showMessagePreview, true);
      expect(settings.notifyEventReminder, true);
      expect(settings.notifyEventChange, true);
      expect(settings.notifyMarketing, false);
      expect(settings.notifyNewsletter, false);
      expect(settings.subscribedRegions, isEmpty);
      expect(settings.subscribedInterests, isEmpty);
    });

    test('fromMap should parse correctly', () {
      final map = {
        'notifyPush': false,
        'subscribedRegions': ['taipei'],
        'subscribedInterests': ['music'],
      };
      final settings = NotificationSettings.fromMap(map);
      expect(settings.notifyPush, false);
      expect(settings.notifyNewMatch, true); // default
      expect(settings.subscribedRegions, ['taipei']);
      expect(settings.subscribedInterests, ['music']);
    });

    test('toMap should serialize correctly', () {
      const settings = NotificationSettings(
        notifyPush: false,
        subscribedRegions: ['taipei'],
        subscribedInterests: ['music'],
      );
      final map = settings.toMap();
      expect(map['notifyPush'], false);
      expect(map['subscribedRegions'], ['taipei']);
      expect(map['subscribedInterests'], ['music']);
    });

    test('copyWith should update fields correctly', () {
      const settings = NotificationSettings();
      final newSettings = settings.copyWith(
        notifyPush: false,
        subscribedRegions: ['taipei'],
      );
      expect(newSettings.notifyPush, false);
      expect(newSettings.subscribedRegions, ['taipei']);
      expect(newSettings.notifyNewMatch, true); // retained
    });
  });
}
