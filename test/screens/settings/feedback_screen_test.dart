import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chingu/screens/settings/feedback_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/feedback_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;

@GenerateNiceMocks([
  MockSpec<AuthProvider>(),
  MockSpec<User>(),
  MockSpec<UserModel>(),
  MockSpec<FeedbackService>(),
])
import 'feedback_screen_test.mocks.dart';

void main() {
  group('FeedbackScreen UI Tests', () {
    late MockAuthProvider mockAuthProvider;
    late MockUserModel mockUserModel;
    late MockFeedbackService mockFeedbackService;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
      mockUserModel = MockUserModel();
      mockFeedbackService = MockFeedbackService();

      when(mockUserModel.email).thenReturn('test@example.com');
      when(mockUserModel.uid).thenReturn('user123');
      when(mockAuthProvider.userModel).thenReturn(mockUserModel);
    });

    Widget createScreen() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: FeedbackScreen(feedbackService: mockFeedbackService),
        ),
      );
    }

    testWidgets('renders all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('意見回饋'), findsOneWidget);
      expect(find.text('回饋類型'), findsOneWidget);
      expect(find.text('詳細說明'), findsOneWidget);
      expect(find.text('聯絡 Email'), findsOneWidget);
      expect(find.text('附件圖片 (可選)'), findsOneWidget);
      expect(find.text('提交回饋'), findsOneWidget);
    });

    testWidgets('pre-fills email from user model', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (WidgetTester tester) async {
      await tester.pumpWidget(createScreen());
      await tester.pumpAndSettle();

      // Clear pre-filled email to test validation
      final emailFinder = find.byKey(const Key('feedback_email_field'));
      await tester.enterText(emailFinder, '');

      final submitFinder = find.byKey(const Key('feedback_submit_button'));
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('請輸入說明內容'), findsOneWidget);
      expect(find.text('請輸入 Email'), findsOneWidget);
    });
  });
}
