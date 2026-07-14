import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly and handles callbacks', (WidgetTester tester) async {
    bool allowed = false;
    bool skipped = false;

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
                      onAllow: () {
                        allowed = true;
                      },
                      onSkip: () {
                        skipped = true;
                      },
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
    expect(find.text('Stay Connected'), findsOneWidget);
    expect(find.text('Enable notifications to get updates on new matches, messages, and dinner events.'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.text('Turn on Notifications'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);

    // Test Allow button
    await tester.tap(find.text('Turn on Notifications'));
    expect(allowed, isTrue);

    // Reset
    allowed = false;

    // Test Skip button
    await tester.tap(find.text('Not Now'));
    expect(skipped, isTrue);
  });
}
