import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/screens/settings/delete_account_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/core/routes/app_router.dart';

// Mocks
class MockAuthService extends Fake implements AuthService {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();
}

class MockFirestoreService extends Fake implements FirestoreService {}

class TestAuthProvider extends AuthProvider {
  TestAuthProvider() : super(
    authService: MockAuthService(),
    firestoreService: MockFirestoreService(),
  );

  bool deleteAccountCalled = false;
  bool exportUserDataCalled = false;
  bool _isLoading = false;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<bool> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10)); // simulate network
    deleteAccountCalled = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 10));
    exportUserDataCalled = true;
    _isLoading = false;
    notifyListeners();
    return {
      'profile': {'name': 'Test User', 'email': 'test@example.com'},
      'moments': []
    };
  }
}

void main() {
  testWidgets('DeleteAccountScreen flow test', (WidgetTester tester) async {
    final authProvider = TestAuthProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const DeleteAccountScreen(),
        ),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );

    // Step 1: Warning
    expect(find.text('警告'), findsOneWidget);
    expect(find.text('下一步'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // Step 2: Export Data
    expect(find.text('資料匯出（可選）'), findsOneWidget);
    expect(find.text('匯出我的資料'), findsOneWidget);

    // Test Export
    await tester.tap(find.text('匯出我的資料'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // wait for future
    await tester.pumpAndSettle(); // wait for dialog animation

    expect(authProvider.exportUserDataCalled, isTrue);

    // Close dialog
    expect(find.text('您的資料'), findsOneWidget);
    await tester.tap(find.text('關閉'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    // Step 3: Confirmation
    expect(find.text('最終確認'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Enter correct text
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();

    // Find and tap Delete button (it's visible now)
    await tester.tap(find.text('確認刪除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(authProvider.deleteAccountCalled, isTrue);
    expect(find.text('帳號已成功刪除'), findsOneWidget);
  });
}
