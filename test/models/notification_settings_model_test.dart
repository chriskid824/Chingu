import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/notification_settings_model.dart';

void main() {
  group('NotificationSettingsModel', () {
    test('supports value equality', () {
      const settingsA = NotificationSettingsModel(
        pushEnabled: true,
        subscribedRegions: ['taipei'],
      );
      const settingsB = NotificationSettingsModel(
        pushEnabled: true,
        subscribedRegions: ['taipei'],
      );
      expect(settingsA, equals(settingsB));
    });

    test('toMap and fromMap work correctly', () {
      const settings = NotificationSettingsModel(
        pushEnabled: false,
        subscribedRegions: ['taichung'],
        subscribedInterests: ['coding'],
      );
      final map = settings.toMap();
      final fromMap = NotificationSettingsModel.fromMap(map);
      expect(fromMap, equals(settings));
    });

    test('copyWith works correctly', () {
      const settings = NotificationSettingsModel();
      final newSettings = settings.copyWith(subscribedRegions: ['kaohsiung']);
      expect(newSettings.subscribedRegions, equals(['kaohsiung']));
      expect(newSettings.pushEnabled, isTrue); // default
    });
  });
}
