import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chingu/screens/auth/login_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';

// Mock 類別
class MockAuthProvider extends Mock implements AuthProvider {}

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
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: const Scaffold(body: LoginScreen()),
      ),
    );
  }

  group('LoginScreen Widget Test', () {
    testWidgets('應成功顯示登入表單與登入按鈕', (WidgetTester tester) async {
      when(() => mockAuthProvider.isLoading).thenReturn(false);

      // 設定模擬的視窗大小，避免溢出錯誤
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 檢查 Email/密碼欄位是否存在
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // 檢查按鈕
      expect(find.text('登入'), findsOneWidget);
      expect(find.text('使用 Google 登入'), findsOneWidget);
    });

    testWidgets('點擊信箱登入時會觸發 AuthProvider', (WidgetTester tester) async {
      when(() => mockAuthProvider.isLoading).thenReturn(false);
      when(() => mockAuthProvider.errorMessage).thenReturn(null);
      when(() => mockAuthProvider.signIn(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => true);

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 輸入信箱與密碼
      final emailField = find.byType(TextFormField).first;
      final passwordField = find.byType(TextFormField).last;

      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pump();

      // 點擊「登入」按鈕
      final loginButton = find.text('登入');
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();

      // 驗證是否被正確呼叫
      verify(() => mockAuthProvider.signIn(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });
  });
}
