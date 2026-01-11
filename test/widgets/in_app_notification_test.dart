import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('InAppNotification renders correctly with text and icon', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'message',
      title: 'New Message',
      message: 'Hello World',
      createdAt: DateTime.now(),
      // imageUrl is null so it should show icon
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(notification: notification),
        ),
      ),
    );

    // Verify title and message
    expect(find.text('New Message'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);

    // Verify icon (message type -> chat_bubble_rounded)
    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
  });

  testWidgets('InAppNotification handles onTap', (WidgetTester tester) async {
    bool tapped = false;
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'System',
      message: 'Update available',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InAppNotification));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('InAppNotification handles onDismiss', (WidgetTester tester) async {
    bool dismissed = false;
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'system',
      title: 'System',
      message: 'Dismiss me',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
            onDismiss: () {
              dismissed = true;
            },
          ),
        ),
      ),
    );

    // Find the close icon
    final closeIcon = find.byIcon(Icons.close_rounded);
    expect(closeIcon, findsOneWidget);

    await tester.tap(closeIcon);
    await tester.pump();

    expect(dismissed, isTrue);
  });
}
