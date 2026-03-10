import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/screens/home/notifications_screen.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('NotificationsScreen displays notifications with content', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: const NotificationsScreen(),
        theme: AppTheme.themeFor(AppThemePreset.orange),
      ),
    );

    // Verify that the title '通知' is displayed.
    expect(find.text('通知'), findsOneWidget);

    // Verify that the content of the first notification is displayed.
    // The first notification content is '王小華 喜歡了您的個人資料'
    expect(find.text('王小華 喜歡了您的個人資料'), findsAtLeastNWidgets(1));

    // Verify that the content of the second notification is displayed.
    // '李小美 傳送了一則訊息給您'
    expect(find.text('李小美 傳送了一則訊息給您'), findsAtLeastNWidgets(1));
  });
}
