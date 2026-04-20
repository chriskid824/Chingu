import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders title and description', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: const Material(child: NotificationPermissionDialog()),
      ),
    );

    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('第一時間收到晚餐配對邀請、聊天訊息和活動提醒。'), findsOneWidget);
    expect(find.text('稍後再說'), findsOneWidget);
    expect(find.text('立即開啟'), findsOneWidget);
  });

  testWidgets('NotificationPermissionDialog show returns true when confirm button is pressed', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.byType(NotificationPermissionDialog), findsOneWidget);

    // Tap '立即開啟'
    await tester.tap(find.text('立即開啟'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('NotificationPermissionDialog show returns false when cancel button is pressed', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.byType(NotificationPermissionDialog), findsOneWidget);

    // Tap '稍後再說'
    await tester.tap(find.text('稍後再說'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
