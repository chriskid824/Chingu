import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  NotificationPermissionDialog.show(
                    context,
                    requestPermissionOnAllow: false
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('為了讓您不錯過任何配對成功、聊天訊息與聚餐提醒，我們建議您開啟通知權限。'), findsOneWidget);
    expect(find.text('暫時不要'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget); // The Allow button
  });

  testWidgets('NotificationPermissionDialog calls onDenied when denied', (WidgetTester tester) async {
    bool deniedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationPermissionDialog(
          onDenied: () => deniedCalled = true,
          requestPermissionOnAllow: false,
        ),
      ),
    );

    await tester.tap(find.text('暫時不要'));
    await tester.pumpAndSettle(); // Allow dialog to close

    expect(deniedCalled, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('NotificationPermissionDialog calls onAllowed when allowed (no request)', (WidgetTester tester) async {
    bool allowedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: NotificationPermissionDialog(
          onAllowed: () => allowedCalled = true,
          requestPermissionOnAllow: false,
        ),
      ),
    );

    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle();

    expect(allowedCalled, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });
}
