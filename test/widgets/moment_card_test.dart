import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('MomentCard displays content and interactions', (WidgetTester tester) async {
    // Arrange
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'Test User',
      content: 'This is a test moment',
      createdAt: DateTime.now(),
      likeCount: 5,
      commentCount: 2,
      isLiked: false,
    );

    bool likeCallbackCalled = false;
    bool commentCallbackCalled = false;
    bool newLikeStatus = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Scaffold(
          body: MomentCard(
            moment: moment,
            onLikeChanged: (isLiked) {
              likeCallbackCalled = true;
              newLikeStatus = isLiked;
            },
            onCommentTap: () {
              commentCallbackCalled = true;
            },
          ),
        ),
      ),
    );

    // Assert Initial State
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('This is a test moment'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // like count
    expect(find.text('2'), findsOneWidget); // comment count
    expect(find.byIcon(Icons.favorite_border), findsOneWidget); // not liked

    // Act: Tap Like
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    // Assert Like Interaction
    expect(likeCallbackCalled, isTrue);
    expect(newLikeStatus, isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget); // liked
    expect(find.text('6'), findsOneWidget); // like count incremented

    // Act: Tap Comment
    await tester.tap(find.byIcon(Icons.chat_bubble_outline));
    await tester.pump();

    // Assert Comment Interaction
    expect(commentCallbackCalled, isTrue);
  });
}
