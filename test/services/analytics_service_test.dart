import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:chingu/services/analytics_service.dart';

// Manual Mock
class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {
  @override
  Future<void> logEvent({required String name, Map<String, Object?>? parameters, AnalyticsCallOptions? callOptions}) {
    return super.noSuchMethod(
      Invocation.method(#logEvent, [], {#name: name, #parameters: parameters, #callOptions: callOptions}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> logScreenView({String? screenClass, String? screenName, AnalyticsCallOptions? callOptions}) {
    return super.noSuchMethod(
      Invocation.method(#logScreenView, [], {#screenClass: screenClass, #screenName: screenName, #callOptions: callOptions}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> setUserId({String? id, AnalyticsCallOptions? callOptions}) {
    return super.noSuchMethod(
      Invocation.method(#setUserId, [], {#id: id, #callOptions: callOptions}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> setUserProperty({required String name, required String? value, AnalyticsCallOptions? callOptions}) {
    return super.noSuchMethod(
      Invocation.method(#setUserProperty, [], {#name: name, #value: value, #callOptions: callOptions}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AnalyticsService analyticsService;
  late MockFirebaseAnalytics mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalytics();
    analyticsService = AnalyticsService();
    analyticsService.analyticsInstance = mockAnalytics;
  });

  test('logEvent calls FirebaseAnalytics.logEvent', () async {
    await analyticsService.logEvent('test_event', parameters: {'key': 'value'});
    verify(mockAnalytics.logEvent(name: 'test_event', parameters: {'key': 'value'})).called(1);
  });

  test('logScreenView calls FirebaseAnalytics.logScreenView', () async {
    await analyticsService.logScreenView(screenName: 'Home');
    verify(mockAnalytics.logScreenView(screenName: 'Home')).called(1);
  });

  test('setUserId calls FirebaseAnalytics.setUserId', () async {
    await analyticsService.setUserId('user123');
    verify(mockAnalytics.setUserId(id: 'user123')).called(1);
  });

  test('setUserProperty calls FirebaseAnalytics.setUserProperty', () async {
    await analyticsService.setUserProperty(name: 'role', value: 'admin');
    verify(mockAnalytics.setUserProperty(name: 'role', value: 'admin')).called(1);
  });
}
