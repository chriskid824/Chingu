import 'package:chingu/models/moment_model.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MomentCard like toggle updates count and icon', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'u1',
      userName: 'Test User',
      content: 'Test Content',
      createdAt: DateTime.now(),
      likeCount: 10,
      isLiked: false,
      commentCount: 5,
    );

    bool? likeStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onLikeChanged: (isLiked) {
              likeStatus = isLiked;
            },
            onCommentTap: () {},
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('10'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    // Tap like
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    // Verify update
    expect(find.text('11'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(likeStatus, true);

    // Tap unlike
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump();

    // Verify update
    expect(find.text('10'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(likeStatus, false);
  });

  testWidgets('MomentCard comment tap triggers callback', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'u1',
      userName: 'Test User',
      content: 'Test Content',
      createdAt: DateTime.now(),
      likeCount: 10,
      isLiked: false,
      commentCount: 5,
    );

    bool commentTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onLikeChanged: (_) {},
            onCommentTap: () {
              commentTapped = true;
            },
          ),
        ),
      ),
    );

    // Verify comment count displayed
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

    // Tap comment
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();

    // Verify callback
    expect(commentTapped, true);
  });
}
