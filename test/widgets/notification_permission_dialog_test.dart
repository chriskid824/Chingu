import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog shows correct content and handles taps', (WidgetTester tester) async {
    // Setup theme
    final theme = AppTheme.themeFor(AppThemePreset.orange);

    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  result = await NotificationPermissionDialog.show(context);
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Show Dialog'), findsOneWidget);

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Stay Connected'), findsOneWidget);
    expect(find.textContaining('Enable notifications to receive real-time updates'), findsOneWidget);
    expect(find.text('Enable Notifications'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

    // Test "Maybe Later" (False)
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(find.text('Stay Connected'), findsNothing); // Dialog closed

    // Re-open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Test "Enable Notifications" (True)
    await tester.tap(find.text('Enable Notifications'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.text('Stay Connected'), findsNothing);
  });
}
