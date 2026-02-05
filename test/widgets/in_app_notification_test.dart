import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('InAppNotificationBanner displays title and message', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'Test Title',
      message: 'Test Message',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
           ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              theme: themeController.theme,
              home: Scaffold(
                body: Stack(
                  children: [
                    InAppNotificationBanner(
                      notification: notification,
                      onDismiss: () {},
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    // Trigger animation
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250)); // Halfway
    await tester.pump(const Duration(milliseconds: 250)); // Finish

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Message'), findsOneWidget);
  });
}
