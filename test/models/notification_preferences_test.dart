import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_preferences.dart';

void main() {
  group('NotificationPreferences', () {
    test('defaults are all true', () {
      final prefs = NotificationPreferences();
      expect(prefs.matchEnabled, isTrue);
      expect(prefs.messageEnabled, isTrue);
      expect(prefs.eventEnabled, isTrue);
    });

    test('toMap works correctly', () {
      final prefs = NotificationPreferences(
        matchEnabled: false,
        messageEnabled: true,
        eventEnabled: false,
      );
      final map = prefs.toMap();
      expect(map['matchEnabled'], isFalse);
      expect(map['messageEnabled'], isTrue);
      expect(map['eventEnabled'], isFalse);
    });

    test('fromMap works correctly', () {
      final map = {
        'matchEnabled': false,
        'messageEnabled': true,
        'eventEnabled': false,
      };
      final prefs = NotificationPreferences.fromMap(map);
      expect(prefs.matchEnabled, isFalse);
      expect(prefs.messageEnabled, isTrue);
      expect(prefs.eventEnabled, isFalse);
    });

    test('copyWith works correctly', () {
      final prefs = NotificationPreferences();
      final newPrefs = prefs.copyWith(matchEnabled: false);
      expect(newPrefs.matchEnabled, isFalse);
      expect(newPrefs.messageEnabled, isTrue); // Should remain default
      expect(newPrefs.eventEnabled, isTrue);
    });
  });
}
