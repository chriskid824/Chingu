import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/moment_card.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/moment_provider.dart';
import 'package:chingu/providers/auth_provider.dart';

// Simple mock/stub since we just want to verify rendering/compilation
class MockMomentProvider extends MomentProvider {
  @override
  Future<void> toggleLike(String momentId, String userId) async {}
}

class MockAuthProvider extends AuthProvider {
  @override
  String? get uid => 'test_uid';
}

void main() {
  testWidgets('MomentCard compiles and renders', (WidgetTester tester) async {
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'User 1',
      content: 'Hello World',
      createdAt: DateTime.now(),
      likeCount: 5,
      commentCount: 2,
      isLiked: false,
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MomentProvider>(create: (_) => MockMomentProvider()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => MockAuthProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MomentCard(moment: moment),
          ),
        ),
      ),
    );

    expect(find.text('Hello World'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
