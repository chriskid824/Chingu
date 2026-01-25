import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('InAppNotification renders correctly', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              theme: themeController.theme,
              home: Scaffold(
                body: InAppNotification(
                  notification: notification,
                ),
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Message'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
  });

  testWidgets('InAppNotification calls onDismiss when dismiss button is tapped', (WidgetTester tester) async {
    bool dismissed = false;
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeController(),
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              theme: themeController.theme,
              home: Scaffold(
                body: InAppNotification(
                  notification: notification,
                  onDismiss: () {
                    dismissed = true;
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
