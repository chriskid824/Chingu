import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correct content and triggers callbacks', (WidgetTester tester) async {
    bool allowed = false;
    bool skipped = false;

    // Use a key to find the widget if needed, or find by text
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NotificationPermissionDialog(
            onAllow: () {
              allowed = true;
            },
            onSkip: () {
              skipped = true;
            },
          ),
        ),
      ),
    );

    // Verify Title and Description
    expect(find.text('開啟通知，不錯過任何機會'), findsOneWidget);
    expect(find.text('即時接收配對成功、新訊息以及晚餐聚會的最新動態。'), findsOneWidget);

    // Verify Icon
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Verify Buttons
    expect(find.widgetWithText(GradientButton, '開啟通知'), findsOneWidget);
    expect(find.text('暫時不要'), findsOneWidget);

    // Test Allow Callback
    await tester.tap(find.widgetWithText(GradientButton, '開啟通知'));
    await tester.pump();
    expect(allowed, isTrue);

    // Test Skip Callback
    await tester.tap(find.text('暫時不要'));
    await tester.pump();
    expect(skipped, isTrue);
  });
}
