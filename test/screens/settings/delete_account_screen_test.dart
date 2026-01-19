import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/screens/settings/delete_account_screen.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Mock AuthService
class MockAuthService extends Mock implements AuthService {
  @override
  Future<void> deleteAccount() async {
    return Future.value();
  }
}

void main() {
  group('DeleteAccountScreen', () {
    testWidgets('renders first step correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeleteAccountScreen()));

      expect(find.text('刪除帳號'), findsOneWidget);
      expect(find.text('您確定要刪除帳號嗎？'), findsOneWidget);
      expect(find.text('此操作無法復原。刪除帳號後：'), findsOneWidget);
      expect(find.text('我了解，繼續'), findsOneWidget);
    });

    testWidgets('navigates to export step', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeleteAccountScreen()));

      await tester.tap(find.text('我了解，繼續'));
      await tester.pumpAndSettle();

      expect(find.text('在離開之前...'), findsOneWidget);
      expect(find.text('您想要下載您的資料副本嗎？'), findsOneWidget);
      expect(find.text('聊天記錄'), findsOneWidget);
      expect(find.text('媒體檔案 (照片/影片)'), findsOneWidget);
      expect(find.text('不需要，跳過'), findsOneWidget);
      expect(find.text('匯出並繼續'), findsOneWidget);
    });

    testWidgets('navigates to confirmation step', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeleteAccountScreen()));

      // Step 1
      await tester.tap(find.text('我了解，繼續'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.text('不需要，跳過'));
      await tester.pumpAndSettle();

      // Step 3
      expect(find.text('最後確認'), findsOneWidget);
      expect(find.text('為了確認刪除您的帳號，請在下方輸入 "DELETE"。'), findsOneWidget);
      expect(find.text('永久刪除帳號'), findsOneWidget);
    });

    testWidgets('validates delete confirmation input', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: DeleteAccountScreen()));

      // Step 1
      await tester.tap(find.text('我了解，繼續'));
      await tester.pumpAndSettle();

      // Step 2
      await tester.tap(find.text('不需要，跳過'));
      await tester.pumpAndSettle();

      // Step 3 - Try to delete without input
      await tester.tap(find.text('永久刪除帳號'));
      await tester.pump();

      expect(find.text('請輸入 "DELETE" 以確認刪除'), findsOneWidget);

      // Input "DELETE"
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      // Tap again (Mocking service call is not fully set up here without dependency injection,
      // but we verify the UI flow up to this point)
    });
  });
}
