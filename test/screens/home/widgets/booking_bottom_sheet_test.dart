import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chingu/screens/home/widgets/booking_bottom_sheet.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/subscription_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:cloud_functions/cloud_functions.dart';

class MockAuthProvider extends Mock implements AuthProvider {}
class MockDinnerEventProvider extends Mock implements DinnerEventProvider {}
class MockSubscriptionProvider extends Mock implements SubscriptionProvider {}
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}
class MockHttpsCallable extends Mock implements HttpsCallable {}
class MockHttpsCallableResult extends Mock implements HttpsCallableResult<Map<String, dynamic>> {}

void main() {
  late MockAuthProvider mockAuthProvider;
  late MockDinnerEventProvider mockEventProvider;
  late MockSubscriptionProvider mockSubProvider;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late MockHttpsCallableResult mockResult;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockEventProvider = MockDinnerEventProvider();
    mockSubProvider = MockSubscriptionProvider();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();
    mockResult = MockHttpsCallableResult();
  });

  Widget createWidgetUnderTest() {
    when(() => mockAuthProvider.uid).thenReturn('user123');

    // Mocks for DinnerEventProvider
    final testDate = DateTime.now().add(const Duration(days: 3));
    when(() => mockEventProvider.getThursdayDates()).thenReturn([testDate]);
    when(() => mockEventProvider.getBookableDates()).thenReturn([testDate]);
    when(() => mockEventProvider.isDateBooked(testDate)).thenReturn(false);
    when(() => mockEventProvider.canBookMore).thenReturn(true);
    when(() => mockEventProvider.activeBookingCount).thenReturn(0);
    when(() => mockEventProvider.fetchMyEvents('user123')).thenAnswer((_) async => null);

    when(() => mockSubProvider.loadSubscription('user123')).thenAnswer((_) async => null);
    when(() => mockSubProvider.isPremium).thenReturn(false);
    when(() => mockSubProvider.freeTrialsRemaining).thenReturn(1);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ChangeNotifierProvider<DinnerEventProvider>.value(value: mockEventProvider),
        ChangeNotifierProvider<SubscriptionProvider>.value(value: mockSubProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: BookingBottomSheet(functions: mockFunctions),
        ),
      ),
    );
  }

  group('BookingBottomSheet Widget Test', () {
    testWidgets('點擊確認報名應該觸發 Firebase Functions', (WidgetTester tester) async {
      when(() => mockFunctions.httpsCallable('bookWithValidation')).thenReturn(mockCallable);
      when(() => mockResult.data).thenReturn({
        'ticketType': 'free',
        'remaining': 0,
      });
      when(() => mockCallable.call<Map<String, dynamic>>(any())).thenAnswer(
        (_) async => mockResult,
      );

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 確認「確認報名」按鈕存在
      final submitBtn = find.text('確認報名');
      expect(submitBtn, findsOneWidget);

      // 點擊確認報名
      await tester.tap(submitBtn);
      await tester.pump(); // 觸發 setState 回圈
      
      // 等待非同步完成 (Snackbar 等動畫)
      await tester.pump(const Duration(seconds: 1));

      // 驗證 callable 是否被正確呼叫
      verify(() => mockFunctions.httpsCallable('bookWithValidation')).called(1);
      verify(() => mockCallable.call<Map<String, dynamic>>(any())).called(1);
    });
  });
}
