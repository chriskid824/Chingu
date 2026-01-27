import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';

void main() {
  testWidgets('NotificationPermissionDialog displays correctly and handles callbacks', (WidgetTester tester) async {
    bool allowPressed = false;
    bool denyPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () {
                NotificationPermissionDialog.show(
                  context,
                  onAllow: () {
                    allowPressed = true;
                  },
                  onDeny: () {
                    denyPressed = true;
                  },
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('開啟通知'), findsNWidgets(2)); // Title and Button text are same

    // Verify Description
    expect(find.text('不錯過任何配對、晚餐活動和好友訊息。保持聯繫，隨時掌握最新動態！'), findsOneWidget);

    // Verify Deny Button
    expect(find.text('暫時不要'), findsOneWidget);

    // Test Deny Callback
    await tester.tap(find.text('暫時不要'));
    await tester.pumpAndSettle();
    expect(denyPressed, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing); // Dialog closed

    // Reset and test Allow Callback
    denyPressed = false;
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap the gradient button. Since text '開啟通知' appears twice (title and button), we need to find the one in the button.
    // The button is likely the second one, but to be sure we can find the GradientButton or check for ancestors.
    // Or just tap the last one.
    await tester.tap(find.text('開啟通知').last);
    await tester.pumpAndSettle();
    expect(allowPressed, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });
}
