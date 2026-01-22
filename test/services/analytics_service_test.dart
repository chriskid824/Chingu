import 'package:chingu/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Manual mock since we cannot run build_runner in this environment
class MockFirebaseAnalyticsWrapper extends Mock implements FirebaseAnalyticsWrapper {
  @override
  Future<void> logEvent({required String name, Map<String, Object>? parameters}) {
    return super.noSuchMethod(
      Invocation.method(#logEvent, [], {#name: name, #parameters: parameters}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> logLogin({String? loginMethod}) {
    return super.noSuchMethod(
      Invocation.method(#logLogin, [], {#loginMethod: loginMethod}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> logSignUp({required String signUpMethod}) {
    return super.noSuchMethod(
      Invocation.method(#logSignUp, [], {#signUpMethod: signUpMethod}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> logScreenView({String? screenClass, String? screenName}) {
    return super.noSuchMethod(
      Invocation.method(#logScreenView, [], {#screenClass: screenClass, #screenName: screenName}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> setUserProperty({required String name, required String? value}) {
    return super.noSuchMethod(
      Invocation.method(#setUserProperty, [], {#name: name, #value: value}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> setUserId({String? id}) {
    return super.noSuchMethod(
      Invocation.method(#setUserId, [], {#id: id}),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

void main() {
  late AnalyticsService analyticsService;
  late MockFirebaseAnalyticsWrapper mockAnalytics;

  setUp(() {
    mockAnalytics = MockFirebaseAnalyticsWrapper();
    analyticsService = AnalyticsService(analytics: mockAnalytics);
  });

  test('logEvent calls wrapper.logEvent', () async {
    const eventName = 'test_event';
    const params = {'key': 'value'};

    await analyticsService.logEvent(eventName, parameters: params);

    verify(mockAnalytics.logEvent(name: eventName, parameters: params)).called(1);
  });

  test('logScreenView calls wrapper.logScreenView', () async {
    const screenName = 'Home';
    const screenClass = 'HomeScreen';

    await analyticsService.logScreenView(screenName, screenClass: screenClass);

    verify(mockAnalytics.logScreenView(screenName: screenName, screenClass: screenClass)).called(1);
  });

  test('logLogin calls wrapper.logLogin', () async {
    const method = 'email';

    await analyticsService.logLogin(method: method);

    verify(mockAnalytics.logLogin(loginMethod: method)).called(1);
  });

  test('logSignUp calls wrapper.logSignUp', () async {
    const method = 'google';

    await analyticsService.logSignUp(method: method);

    verify(mockAnalytics.logSignUp(signUpMethod: method)).called(1);
  });

  test('setUserProperty calls wrapper.setUserProperty', () async {
    const name = 'user_type';
    const value = 'premium';

    await analyticsService.setUserProperty(name, value);

    verify(mockAnalytics.setUserProperty(name: name, value: value)).called(1);
  });

  test('setUserId calls wrapper.setUserId', () async {
    const id = '123456';

    await analyticsService.setUserId(id);

    verify(mockAnalytics.setUserId(id: id)).called(1);
  });
}
