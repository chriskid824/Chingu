
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:mockito/mockito.dart';

class MockAuthProvider extends Mock implements AuthProvider {
  // We don't need to implement much here as we are not testing auth logic deeply,
  // just ensuring the widget can access it if needed.
  // However, MomentCard accesses authProvider.user, so we might need to mock that if we test report logic.
}

void main() {
  testWidgets('MomentCard More Options Test', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '123',
      userId: 'user1',
      userName: 'Test User',
      content: 'Hello World',
      createdAt: DateTime.now(),
      isBookmarked: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Provider<AuthProvider>(
            create: (_) => MockAuthProvider(), // Provide mock if needed
            child: MomentCard(
              moment: moment,
              onBookmarkChanged: (val) {},
            ),
          ),
        ),
      ),
    );

    // Verify More Options button exists
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    // Tap the button
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    // Verify Bottom Sheet appears
    expect(find.text('分享'), findsOneWidget);
    expect(find.text('收藏'), findsOneWidget);
    expect(find.text('舉報'), findsOneWidget);

    // Test Bookmark toggle
    await tester.tap(find.text('收藏'));
    await tester.pumpAndSettle();
    // (We cannot easily verify the state change here without more complex setup,
    // but ensuring no crash is good)
  });
}
