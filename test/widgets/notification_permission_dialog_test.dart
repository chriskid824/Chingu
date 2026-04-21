import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: const Scaffold(
          body: NotificationPermissionDialog(),
        ),
      ),
    );

    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
    expect(find.text('不錯過任何消息'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('暫不開啟'), findsOneWidget);
  });

  testWidgets('NotificationPermissionDialog calls onAllow and closes', (WidgetTester tester) async {
    bool allowCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  NotificationPermissionDialog.show(
                    context,
                    onAllow: () async {
                      allowCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap Allow
    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle();

    expect(allowCalled, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('NotificationPermissionDialog calls onSkip and closes', (WidgetTester tester) async {
    bool skipCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  NotificationPermissionDialog.show(
                    context,
                    onSkip: () {
                      skipCalled = true;
                    },
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap Skip
    await tester.tap(find.text('暫不開啟'));
    await tester.pumpAndSettle();

    expect(skipCalled, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });
}
