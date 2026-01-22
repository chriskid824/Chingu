import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:chingu/screens/profile/report_user_screen.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';

// Mock FirestoreService
class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<void> submitUserReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #submitUserReport,
        [],
        {
          #reporterId: reporterId,
          #reportedUserId: reportedUserId,
          #reason: reason,
          #description: description,
        },
      ),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  String? get uid => 'test_reporter_id';

  @override
  bool get hasListeners => false;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void notifyListeners() {}
}

void main() {
  testWidgets('ReportUserScreen UI and submission test', (WidgetTester tester) async {
    final mockFirestoreService = MockFirestoreService();
    final mockAuthProvider = MockAuthProvider();

    // Stub the submit method
    when(mockFirestoreService.submitUserReport(
      reporterId: anyNamed('reporterId'),
      reportedUserId: anyNamed('reportedUserId'),
      reason: anyNamed('reason'),
      description: anyNamed('description'),
    )).thenAnswer((_) async {});

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              theme: themeController.theme,
              home: ReportUserScreen(
                reportedUserId: 'test_reported_user',
                reportedUserName: 'Bad User',
                firestoreService: mockFirestoreService,
              ),
            );
          },
        ),
      ),
    );

    // Verify UI elements
    expect(find.text('舉報用戶'), findsOneWidget);
    expect(find.text('舉報對象: Bad User'), findsOneWidget);
    expect(find.text('騷擾行為'), findsOneWidget);
    expect(find.text('提交舉報'), findsOneWidget);

    // Select a reason
    await tester.tap(find.text('騷擾行為'));
    await tester.pump();

    // Enter description
    await tester.enterText(find.byType(TextFormField), 'He was rude.');
    await tester.pump();

    // Tap submit
    await tester.tap(find.text('提交舉報'));
    await tester.pumpAndSettle();

    // Verify submission called
    verify(mockFirestoreService.submitUserReport(
      reporterId: 'test_reporter_id',
      reportedUserId: 'test_reported_user',
      reason: '騷擾行為',
      description: 'He was rude.',
    )).called(1);
  });
}
