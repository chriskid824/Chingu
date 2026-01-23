import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/widgets/gradient_button.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationPermissionDialog(),
      ),
    );

    expect(find.text('開啟通知，不錯過任何機會'), findsOneWidget);
    expect(find.text('即時收到配對成功、新訊息以及晚餐聚會的提醒。'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('暫時不要'), findsOneWidget);
    expect(find.byType(Icon), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
  });

  testWidgets('Tapping Enable Notifications returns true', (WidgetTester tester) async {
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

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap "開啟通知"
    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('Tapping Not Now returns false', (WidgetTester tester) async {
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

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap "暫時不要"
    await tester.tap(find.text('暫時不要'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
