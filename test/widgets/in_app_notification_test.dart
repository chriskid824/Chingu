import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  final notification = NotificationModel(
    id: '1',
    userId: 'user1',
    type: 'match',
    title: 'New Match!',
    message: 'You have a new match with Alice',
    createdAt: DateTime.now(),
  );

  testWidgets('InAppNotification renders title and message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
          ),
        ),
      ),
    );

    expect(find.text('New Match!'), findsOneWidget);
    expect(find.text('You have a new match with Alice'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget); // Match uses favorite icon
  });

  testWidgets('InAppNotification handles onTap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InAppNotification));
    expect(tapped, isTrue);
  });

  testWidgets('InAppNotification handles onDismiss', (WidgetTester tester) async {
    bool dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    expect(dismissed, isTrue);
  });

  testWidgets('InAppNotification renders different icon for message type', (WidgetTester tester) async {
     final messageNotification = NotificationModel(
      id: '2',
      userId: 'user1',
      type: 'message',
      title: 'New Message',
      message: 'Hello',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: Scaffold(
          body: InAppNotification(
            notification: messageNotification,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
  });
}
