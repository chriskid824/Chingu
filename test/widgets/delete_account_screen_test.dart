import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/screens/settings/delete_account_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  bool get isLoading => false;

  @override
  String? get errorMessage => null;

  @override
  Future<bool> deleteAccount() async => true;
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DeleteAccountScreen(),
      ),
    );
  }

  testWidgets('DeleteAccountScreen shows warning step initially', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('刪除帳號'), findsOneWidget);
    expect(find.text('警告'), findsOneWidget);
    expect(find.text('刪除帳號是不可逆的'), findsOneWidget);
    expect(find.text('我了解此操作無法復原'), findsOneWidget);
  });

  testWidgets('DeleteAccountScreen navigates to export step after acknowledgement', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Check acknowledgement
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    // Tap Continue
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();

    expect(find.text('備份您的資料'), findsOneWidget);
    expect(find.text('不需要備份，繼續'), findsOneWidget);
  });

  testWidgets('DeleteAccountScreen navigates to confirmation step', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Step 1
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();

    // Step 2
    await tester.tap(find.text('不需要備份，繼續'));
    await tester.pumpAndSettle();

    // Step 3
    expect(find.text('最後確認'), findsOneWidget);
    expect(find.text('確認永久刪除'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
