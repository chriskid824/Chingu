import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/core/theme/app_theme.dart';
// import 'package:intl/date_symbol_data_local.dart'; // Might need this if Locale is used, but default is usually fine.

void main() {
  testWidgets('MomentCard shows initial comment count', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'User 1',
      content: 'Content',
      createdAt: DateTime.now(),
      commentCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ChinguTheme(
              primaryGradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
              secondaryGradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
              transparentGradient: const LinearGradient(colors: [Colors.transparent, Colors.transparent]),
              successGradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
              glassGradient: const LinearGradient(colors: [Colors.white, Colors.white10]),
              surfaceVariant: Colors.grey[200]!,
              shadowLight: Colors.black12,
              shadowMedium: Colors.black26,
              secondary: Colors.orange,
              info: Colors.blue,
              success: Colors.green,
              warning: Colors.yellow,
              error: Colors.red,
            ),
          ],
        ),
        home: Scaffold(
          body: MomentCard(moment: moment),
        ),
      ),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });

  testWidgets('MomentCard opens comment sheet and adds comment', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'User 1',
      content: 'Content',
      createdAt: DateTime.now(),
      commentCount: 0,
    );

    String? addedComment;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ChinguTheme(
              primaryGradient: const LinearGradient(colors: [Colors.blue, Colors.purple]),
              secondaryGradient: const LinearGradient(colors: [Colors.orange, Colors.red]),
              transparentGradient: const LinearGradient(colors: [Colors.transparent, Colors.transparent]),
              successGradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
              glassGradient: const LinearGradient(colors: [Colors.white, Colors.white10]),
              surfaceVariant: Colors.grey[200]!,
              shadowLight: Colors.black12,
              shadowMedium: Colors.black26,
              secondary: Colors.orange,
              info: Colors.blue,
              success: Colors.green,
              warning: Colors.yellow,
              error: Colors.red,
            ),
          ],
        ),
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onAddComment: (text) {
              addedComment = text;
            },
          ),
        ),
      ),
    );

    // Tap comment button
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pumpAndSettle();

    // Verify sheet is open
    expect(find.text('留言 (0)'), findsOneWidget);
    expect(find.text('新增留言...'), findsOneWidget);

    // Enter comment
    await tester.enterText(find.byType(TextField), 'New Comment');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(); // Rebuild for state update

    // Verify comment is added in the list (sheet is still open)
    expect(find.text('New Comment'), findsOneWidget);
    expect(find.text('留言 (1)'), findsOneWidget);

    // Need to close the bottom sheet to see the card update?
    // The card update happens via setState inside _handleAddComment which updates the local state of MomentCard?
    // Wait, _handleAddComment is in MomentCardState. When called, it calls setState.
    // So the card should update. However, the sheet is covering it.

    // Tap outside to close
    await tester.tapAt(const Offset(0, 0));
    await tester.pumpAndSettle();

    // Verify comment count on card updated
    expect(find.text('1'), findsOneWidget);

    // Verify callback was called
    expect(addedComment, 'New Comment');
  });
}
