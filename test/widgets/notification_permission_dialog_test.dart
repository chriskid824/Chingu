import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correctly and handles callbacks', (WidgetTester tester) async {
    bool allowPressed = false;
    bool denyPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: NotificationPermissionDialog(
            onAllow: () => allowPressed = true,
            onDeny: () => denyPressed = true,
          ),
        ),
      ),
    );

    // Verify title and button text (both have same text)
    expect(find.text('開啟通知'), findsNWidgets(2));

    // Verify description
    expect(find.text('開啟通知以確保您不會錯過任何晚餐配對、聊天訊息或重要活動提醒。'), findsOneWidget);

    // Verify buttons
    expect(find.widgetWithText(GradientButton, '開啟通知'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '稍後再說'), findsOneWidget);

    // Tap Allow
    await tester.tap(find.widgetWithText(GradientButton, '開啟通知'));
    expect(allowPressed, isTrue);

    // Tap Deny
    await tester.tap(find.widgetWithText(TextButton, '稍後再說'));
    expect(denyPressed, isTrue);
  });
}
