import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/screens/settings/delete_account_screen.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

void main() {
  group('DeleteAccountScreen', () {
    testWidgets('renders first step (reason selection) correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DeleteAccountScreen(),
          theme: AppTheme.lightTheme,
        ),
      );

      expect(find.text('為什麼想要離開？'), findsOneWidget);
      expect(find.text('覺得找不到合適的對象'), findsOneWidget);
      expect(find.text('下一步'), findsOneWidget);
    });

    testWidgets('can navigate to export step after selecting reason', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DeleteAccountScreen(),
          theme: AppTheme.lightTheme,
        ),
      );

      // Verify button is disabled initially
      final nextButton = tester.widget<GradientButton>(find.byType(GradientButton));
      expect(nextButton.onPressed, isNull);

      // Select a reason
      await tester.tap(find.text('其他原因'));
      await tester.pump();

      // Verify button is enabled
      final nextButtonEnabled = tester.widget<GradientButton>(find.byType(GradientButton));
      expect(nextButtonEnabled.onPressed, isNotNull);

      // Tap Next
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      // Check if we are on the export step
      expect(find.text('備份您的資料'), findsOneWidget);
    });

    testWidgets('can navigate to confirmation step and delete', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DeleteAccountScreen(),
          theme: AppTheme.lightTheme,
        ),
      );

      // Step 1: Reason
      await tester.tap(find.text('其他原因'));
      await tester.pump();
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      // Step 2: Export (Skip)
      expect(find.text('備份您的資料'), findsOneWidget);
      await tester.tap(find.byType(GradientButton));
      await tester.pumpAndSettle();

      // Step 3: Confirmation
      expect(find.text('最終確認'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Verify delete button is disabled initially
      final deleteButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(deleteButton.onPressed, isNull);

      // Enter "DELETE"
      await tester.enterText(find.byType(TextField), 'DELETE');
      await tester.pump();

      // Verify delete button is enabled
      final deleteButtonEnabled = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(deleteButtonEnabled.onPressed, isNotNull);

      // Tap Delete
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Since we just pop in implementation, verify we are not on the screen anymore?
      // But here we are the root, so pop might not do much in test env without navigator observer.
      // But we can verify the button tap happened.
    });
  });
}
