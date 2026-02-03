import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/rich_notification_service.dart';

void main() {
  test('Verify RichNotificationService compilation', () {
    expect(RichNotificationService, isNotNull);
    // We don't instantiate it to avoid missing plugin errors,
    // but just importing it verifies syntax and imports.
  });
}
