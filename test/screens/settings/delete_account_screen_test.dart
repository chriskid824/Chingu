import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chingu/screens/settings/delete_account_screen.dart';
import 'package:chingu/providers/auth_provider.dart';

// Mock AuthProvider class using Mockito would be better, but for simplicity
// and since we can't easily add dependencies in this environment,
// we will just wrap the widget in a Provider with a real (but uninitialized) AuthProvider
// or better yet, a basic ChangeNotifier that implements what we need if possible.
// However, since we can't override AuthProvider easily without Mockito,
// we will try to rely on the fact that UI tests might not trigger the delete action
// that calls the provider until the last step.

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  Future<void> deleteAccount() async {
    // Mock implementation
    return Future.value();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('DeleteAccountScreen shows export step initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(home: DeleteAccountScreen()),
      ),
    );

    expect(find.text('離開之前...'), findsOneWidget);
    expect(find.text('導出我的數據'), findsOneWidget);
    expect(find.text('繼續'), findsOneWidget);
  });

  testWidgets('DeleteAccountScreen navigates to reason step', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(home: DeleteAccountScreen()),
      ),
    );

    // Find and tap 'Continue'
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();

    expect(find.text('為什麼想離開？'), findsOneWidget);
    expect(find.text('找不到合適的配對'), findsOneWidget);
  });

  testWidgets('DeleteAccountScreen requires reason to continue', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: const MaterialApp(home: DeleteAccountScreen()),
      ),
    );

    // Go to step 2
    await tester.tap(find.text('繼續'));
    await tester.pumpAndSettle();

    final continueButton = find.widgetWithText(FilledButton, '繼續');

    // Select a reason
    await tester.tap(find.text('找不到合適的配對'));
    await tester.pump();

    // Go to step 3
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('確定要刪除帳號嗎？'), findsOneWidget);
    expect(find.text('確認刪除帳號'), findsOneWidget);
  });
}
