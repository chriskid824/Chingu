import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('MomentCard displays moment details correctly', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Test User',
      content: 'Hello World',
      createdAt: DateTime.now(),
      likeCount: 10,
      commentCount: 5,
      isLiked: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MomentCard(moment: moment),
        ),
      ),
    );

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('MomentCard toggles like state', (WidgetTester tester) async {
    bool? capturedLikeState;
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Test User',
      content: 'Hello World',
      createdAt: DateTime.now(),
      likeCount: 10,
      commentCount: 5,
      isLiked: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onLikeChanged: (isLiked) {
              capturedLikeState = isLiked;
            },
          ),
        ),
      ),
    );

    // Initial state
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Tap like button
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    // Verify state change
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(capturedLikeState, isTrue);

    // Tap again to unlike
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();

    // Verify state reverted
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(capturedLikeState, isFalse);
  });

  testWidgets('MomentCard triggers onCommentTap', (WidgetTester tester) async {
    bool commentTapped = false;
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Test User',
      content: 'Hello World',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onCommentTap: () {
              commentTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    expect(commentTapped, isTrue);
  });
}
