import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correctly and handles taps', (WidgetTester tester) async {
    bool allowCalled = false;
    bool denyCalled = false;

    // Use the default orange theme for testing
    const chinguTheme = ChinguTheme.orange;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [chinguTheme],
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  NotificationPermissionDialog.show(
                    context,
                    onAllow: () {
                      allowCalled = true;
                    },
                    onDeny: () {
                      denyCalled = true;
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

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Stay Connected'), findsOneWidget);
    expect(find.text('Turn on Notifications'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);

    // Test Allow button
    await tester.tap(find.text('Turn on Notifications'));
    await tester.pumpAndSettle();
    expect(allowCalled, isTrue);
    expect(denyCalled, isFalse);

    // Reset and test Deny button
    allowCalled = false;
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(allowCalled, isFalse);
    expect(denyCalled, isTrue);
  });
}
