import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyStateWidget displays icon, title, description, and button', (WidgetTester tester) async {
    const icon = Icons.info;
    const title = 'Nothing here';
    const description = 'Please check back later.';
    const actionLabel = 'Retry';
    bool actionPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            icon: icon,
            title: title,
            description: description,
            actionLabel: actionLabel,
            onActionPressed: () {
              actionPressed = true;
            },
          ),
        ),
      ),
    );

    // Verify Icon
    expect(find.byIcon(icon), findsOneWidget);

    // Verify Title
    expect(find.text(title), findsOneWidget);

    // Verify Description
    expect(find.text(description), findsOneWidget);

    // Verify Button
    expect(find.text(actionLabel), findsOneWidget);

    // Verify Action
    await tester.tap(find.text(actionLabel));
    expect(actionPressed, isTrue);
  });

  testWidgets('EmptyStateWidget works with custom widget icon', (WidgetTester tester) async {
    const title = 'Custom Icon';
    const customKey = Key('custom_icon');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            iconWidget: Container(key: customKey, width: 50, height: 50, color: Colors.red),
            title: title,
          ),
        ),
      ),
    );

    expect(find.byKey(customKey), findsOneWidget);
    expect(find.text(title), findsOneWidget);
  });
}
