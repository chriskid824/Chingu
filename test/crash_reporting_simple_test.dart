import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/crash_reporting_service.dart';

void main() {
  test('CrashReportingService singleton works', () {
    final service1 = CrashReportingService();
    final service2 = CrashReportingService();
    expect(service1, equals(service2));
  });
}
