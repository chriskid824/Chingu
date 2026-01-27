import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/in_app_notification.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  Widget createWidgetUnderTest({
    required String title,
    required String message,
    InAppNotificationType type = InAppNotificationType.standard,
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    return MaterialApp(
      theme: AppTheme.themeFor(AppThemePreset.minimal),
      home: Scaffold(
        body: InAppNotification(
          title: title,
          message: message,
          type: type,
          onTap: onTap,
          onDismiss: onDismiss,
        ),
      ),
    );
  }

  testWidgets('InAppNotification renders title and message', (WidgetTester tester) async {
    const title = 'Test Title';
    const message = 'Test Message';

    await tester.pumpWidget(createWidgetUnderTest(
      title: title,
      message: message,
    ));

    expect(find.text(title), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    // Default type is standard, checks for standard icon
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });

  testWidgets('InAppNotification renders success icon', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Success',
      message: 'Operation successful',
      type: InAppNotificationType.success,
    ));

    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });

  testWidgets('InAppNotification calls onTap when tapped', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Tap Me',
      message: 'Clickable',
      onTap: () => tapped = true,
    ));

    await tester.tap(find.byType(InAppNotification));
    expect(tapped, isTrue);
  });

  testWidgets('InAppNotification shows dismiss button and calls onDismiss', (WidgetTester tester) async {
    bool dismissed = false;
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'Dismiss Me',
      message: 'Closable',
      onDismiss: () => dismissed = true,
    ));

    final dismissButton = find.byIcon(Icons.close);
    expect(dismissButton, findsOneWidget);

    await tester.tap(dismissButton);
    expect(dismissed, isTrue);
  });

  testWidgets('InAppNotification does not show dismiss button if onDismiss is null', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest(
      title: 'No Dismiss',
      message: 'Persistent',
      onDismiss: null,
    ));

    expect(find.byIcon(Icons.close), findsNothing);
  });
}
