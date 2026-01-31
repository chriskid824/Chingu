import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    test('should be a singleton', () {
      final service1 = CrashReportingService();
      final service2 = CrashReportingService();

      expect(service1, equals(service2));
      expect(identical(service1, service2), isTrue);
    });

    test('should have expected methods', () {
      final service = CrashReportingService();

      // Verify methods exist (by referencing them, compilation check effectively)
      expect(service.initialize, isNotNull);
      expect(service.log, isNotNull);
      expect(service.recordError, isNotNull);
      expect(service.setUserIdentifier, isNotNull);
      expect(service.setCustomKey, isNotNull);
    });
  });
}
