import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correctly and handles clicks',
      (WidgetTester tester) async {
    bool allowed = false;
    bool denied = false;

    // Use a ThemeController or just pump a MaterialApp with a theme
    final theme = AppTheme.themeFor(AppThemePreset.orange);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: NotificationPermissionDialog(
            onAllow: () => allowed = true,
            onDeny: () => denied = true,
          ),
        ),
      ),
    );

    // Verify Title and Button text exist (total 2 occurrences)
    expect(find.text('開啟通知'), findsNWidgets(2));

    // Verify Body
    expect(find.text('開啟通知以確保您不會錯過配對成功、新訊息或晚餐活動的邀請。'), findsOneWidget);

    // Verify Icon
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Verify "Maybe Later" Button
    expect(find.text('稍後再說'), findsOneWidget);

    // Tap Allow (find the button specifically)
    await tester.tap(find.widgetWithText(ElevatedButton, '開啟通知'));
    expect(allowed, isTrue);

    // Tap Deny
    await tester.tap(find.text('稍後再說'));
    expect(denied, isTrue);
  });
}
