import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

void main() {
  testWidgets('NotificationPermissionDialog returns false on "暫不開啟"', (WidgetTester tester) async {
    await _pumpApp(tester);

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('不錯過任何消息'), findsOneWidget);

    // Tap "暫不開啟"
    await tester.tap(find.widgetWithText(TextButton, '暫不開啟'));
    await tester.pumpAndSettle();

    // Verify result
    expect(find.text('Result: false'), findsOneWidget);
  });

  testWidgets('NotificationPermissionDialog returns true on "開啟通知"', (WidgetTester tester) async {
    await _pumpApp(tester);

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('不錯過任何消息'), findsOneWidget);

    // Tap "開啟通知"
    await tester.tap(find.widgetWithText(GradientButton, '開啟通知'));
    await tester.pumpAndSettle();

    // Verify result
    expect(find.text('Result: true'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeFor(AppThemePreset.minimal),
      home: Builder(
        builder: (context) {
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await NotificationPermissionDialog.show(context);
                  showDialog(
                    context: context,
                    builder: (_) => Text('Result: $result'),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          );
        },
      ),
    ),
  );
}
