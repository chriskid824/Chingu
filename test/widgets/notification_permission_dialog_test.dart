import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correct content and handles clicks', (WidgetTester tester) async {
    bool allowClicked = false;
    bool skipClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  NotificationPermissionDialog.show(
                    context,
                    onAllow: () => allowClicked = true,
                    onSkip: () => skipClicked = true,
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify content
    expect(find.text('開啟通知，不錯過任何機會'), findsOneWidget);
    expect(find.text('接收配對成功、晚餐活動及新訊息的即時通知，讓您隨時掌握最新動態。'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('暫時不要'), findsOneWidget);

    // Test Allow button
    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle(); // Wait for dialog to close
    expect(allowClicked, isTrue);
    expect(find.text('開啟通知，不錯過任何機會'), findsNothing); // Dialog closed

    // Re-open dialog to test Skip button
    allowClicked = false;
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('暫時不要'));
    await tester.pumpAndSettle();
    expect(skipClicked, isTrue);
    expect(find.text('開啟通知，不錯過任何機會'), findsNothing);
  });
}
