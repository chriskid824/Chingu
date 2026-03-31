import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/crash_reporting_service.dart';

void main() {
  group('CrashReportingService', () {
    test('is a singleton', () {
      final service1 = CrashReportingService();
      final service2 = CrashReportingService();
      expect(service1, equals(service2));
    });

    // Note: detailed testing of initialize, log, recordError requires mocking FirebaseCrashlytics.instance
    // which is static and final. To test those, we would need to refactor CrashReportingService
    // to accept a dependency or use a wrapper.
    // For now, we verify the service structure exists.
  });
}
