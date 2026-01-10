import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/avatar_badge.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('AvatarBadge renders correctly', (WidgetTester tester) async {
    // Basic test to ensure no crash on render
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AvatarBadge(
            imageUrl: null, // Test fallback
            isOnline: true,
          ),
        ),
      ),
    );

    // Verify avatar container exists
    expect(find.byType(AvatarBadge), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);

    // We can't easily find the colored container without keys or more complex finding,
    // but finding the widget itself is a good start for this environment.
  });
}
