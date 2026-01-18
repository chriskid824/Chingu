import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('NotificationSettingsModel', () {
    test('defaults are all true', () {
      const settings = NotificationSettingsModel();
      expect(settings.matchNotifications, true);
      expect(settings.messageNotifications, true);
      expect(settings.eventNotifications, true);
    });

    test('fromMap parses correctly', () {
      final map = {
        'matchNotifications': false,
        'messageNotifications': true,
        'eventNotifications': false,
      };
      final settings = NotificationSettingsModel.fromMap(map);
      expect(settings.matchNotifications, false);
      expect(settings.messageNotifications, true);
      expect(settings.eventNotifications, false);
    });

    test('fromMap handles missing keys with defaults', () {
      final map = <String, dynamic>{};
      final settings = NotificationSettingsModel.fromMap(map);
      expect(settings.matchNotifications, true);
      expect(settings.messageNotifications, true);
      expect(settings.eventNotifications, true);
    });

    test('toMap serializes correctly', () {
      const settings = NotificationSettingsModel(
        matchNotifications: false,
        messageNotifications: true,
        eventNotifications: false,
      );
      final map = settings.toMap();
      expect(map['matchNotifications'], false);
      expect(map['messageNotifications'], true);
      expect(map['eventNotifications'], false);
    });

    test('copyWith updates fields correctly', () {
      const settings = NotificationSettingsModel();
      final newSettings = settings.copyWith(matchNotifications: false);
      expect(newSettings.matchNotifications, false);
      expect(newSettings.messageNotifications, true);
      expect(newSettings.eventNotifications, true);
    });
  });
}
