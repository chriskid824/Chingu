import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog UI and interaction test', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('不錯過任何精彩時刻'), findsOneWidget);
    expect(find.text('開啟通知，第一時間收到配對成功、新訊息和晚餐活動的提醒。'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('稍後再說'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Tap "稍後再說" (Cancel)
    await tester.tap(find.text('稍後再說'));
    await tester.pumpAndSettle();

    expect(result, false);

    // Show dialog again
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap "開啟通知" (Confirm)
    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle();

    expect(result, true);
  });
}
