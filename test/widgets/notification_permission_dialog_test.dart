import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly and handles taps', (WidgetTester tester) async {
    bool allowed = false;
    bool denied = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    NotificationPermissionDialog.show(
                      context,
                      onAllow: () => allowed = true,
                      onDeny: () => denied = true,
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

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('為了讓您不錯過任何配對成功、新訊息或活動提醒，請允許我們發送通知。'), findsOneWidget);
    expect(find.text('好的'), findsOneWidget);
    expect(find.text('稍後再說'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Test Allow button
    await tester.tap(find.text('好的'));
    await tester.pumpAndSettle();

    expect(allowed, isTrue);
    expect(denied, isFalse);
    expect(find.text('開啟通知'), findsNothing); // Dialog should be closed

    // Reset and test Deny button
    allowed = false;
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('稍後再說'));
    await tester.pumpAndSettle();

    expect(allowed, isFalse);
    expect(denied, isTrue);
    expect(find.text('開啟通知'), findsNothing); // Dialog should be closed
  });
}
