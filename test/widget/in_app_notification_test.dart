import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('InAppNotification renders correctly', (WidgetTester tester) async {
    final notification = NotificationModel(
      id: '1',
      userId: 'user1',
      type: 'match',
      title: 'New Match',
      message: 'You have a new match!',
      createdAt: DateTime.now(),
    );

    // Create a theme that includes ChinguTheme extension
    final theme = AppTheme.themeFor(AppThemePreset.orange);

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: InAppNotification(
            notification: notification,
            onDismiss: () {},
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('New Match'), findsOneWidget);
    expect(find.text('You have a new match!'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });
}
