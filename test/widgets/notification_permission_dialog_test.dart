import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    // Build the dialog
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => NotificationPermissionDialog.show(context),
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog elements
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.textContaining('為了不錯過任何配對成功'), findsOneWidget);
    expect(find.text('暫不開啟'), findsOneWidget);
    expect(find.text('好，開啟'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
  });

  testWidgets('NotificationPermissionDialog skip button closes dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => NotificationPermissionDialog.show(context),
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap Skip
    await tester.tap(find.text('暫不開啟'));
    await tester.pumpAndSettle();

    // Verify dialog closed
    expect(find.text('開啟通知'), findsNothing);
  });
}
