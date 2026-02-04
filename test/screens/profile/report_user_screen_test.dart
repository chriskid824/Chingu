import 'package:chingu/screens/profile/report_user_screen.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Fake AuthProvider for testing
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  String? get uid => 'test_reporter_id';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Just return null or throw for other methods if accessed
    return null;
  }
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreService firestoreService;
  late FakeAuthProvider fakeAuthProvider;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
    fakeAuthProvider = FakeAuthProvider();
  });

  Widget createWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: fakeAuthProvider),
      ],
      child: MaterialApp(
        // Use a basic theme or ChinguTheme
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: ReportUserScreen(
          reportedUserId: 'bad_user_id',
          reportedUserName: 'Bad Guy',
          firestoreService: firestoreService,
        ),
      ),
    );
  }

  testWidgets('ReportUserScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    expect(find.text('舉報用戶'), findsOneWidget);
    expect(find.text('舉報對象: Bad Guy'), findsOneWidget);
    expect(find.text('請選擇舉報原因'), findsOneWidget);
    expect(find.text('垃圾訊息 / 詐騙'), findsOneWidget);
  });

  testWidgets('Submit report with validation error (no reason selected)', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // Scroll to button
    await tester.ensureVisible(find.text('提交舉報'));

    // Tap submit without selecting reason
    await tester.tap(find.text('提交舉報'));
    await tester.pump(); // Rebuild

    // Expect SnackBar (One is the label, one is the snackbar)
    expect(find.text('請選擇舉報原因'), findsNWidgets(2));
  });

  testWidgets('Submit report successfully', (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // Select reason
    await tester.tap(find.text('騷擾行為'));
    await tester.pump();

    // Enter description
    await tester.enterText(find.byType(TextFormField), 'He was rude.');
    await tester.pump();

    // Scroll to button
    await tester.ensureVisible(find.text('提交舉報'));

    // Tap submit
    await tester.tap(find.text('提交舉報'));

    // Process microtasks and animations
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify Firestore
    final snapshot = await fakeFirestore.collection('reports').get();
    expect(snapshot.docs.length, 1);
    final data = snapshot.docs.first.data();
    expect(data['reporterId'], 'test_reporter_id');
    expect(data['reportedUserId'], 'bad_user_id');
    expect(data['reason'], '騷擾行為');
    expect(data['description'], 'He was rude.');

    // Verify success snackbar or navigation
    // Since Navigator.pop is called, the screen might be gone or SnackBar visible.
    // If pop happened, we can check if we are back to "home" (which we didn't define properly in test)
    // or just assume if Firestore write happened, it's good.

    // Attempt to find snackbar, but if pop happened it might be tricky in test env.
    // Let's just check that the operation completed (implied by firestore write).
  });
}
