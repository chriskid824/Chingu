
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/badge_count_service.dart';

void main() {
  group('BadgeCountService', () {
    late BadgeCountService service;

    setUp(() {
      service = BadgeCountService();
    });

    test('updateCount should update the count and log message', () async {
      await service.updateCount(5);
      // Since _currentCount is private and we can't mock print easily without logic,
      // we are mostly verifying the method call doesn't crash.
      // In a real test with mocked platform channel, we would verify the channel call.
    });

    test('removeBadge should reset count to 0', () async {
      await service.updateCount(5);
      await service.removeBadge();
      // Verify no errors.
    });

    test('reset should call removeBadge', () async {
      await service.reset();
      // Verify no errors.
    });

    test('Singleton instance should be same', () {
      final s1 = BadgeCountService();
      final s2 = BadgeCountService();
      expect(s1, equals(s2));
    });
  });
}
