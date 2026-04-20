import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: NotificationPermissionDialog(),
        ),
      ),
    );

    expect(find.text('開啟通知，不錯過重要訊息'), findsOneWidget);
    expect(find.text('為了確保您能即時收到配對成功、新訊息以及活動提醒，我們建議您開啟通知權限。'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('稍後再說'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);
  });

  testWidgets('NotificationPermissionDialog returns false on "Later"', (WidgetTester tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('開啟通知，不錯過重要訊息'), findsOneWidget);

    // Tap "Later"
    await tester.tap(find.text('稍後再說'));
    await tester.pumpAndSettle();

    // Verify result
    expect(result, isFalse);
    expect(find.text('開啟通知，不錯過重要訊息'), findsNothing);
  });
}
