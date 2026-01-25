import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/screens/matching/user_detail_screen.dart';
import 'package:chingu/core/theme/app_theme.dart';

void main() {
  testWidgets('UserDetailScreen has report button', (WidgetTester tester) async {
    // Build the UserDetailScreen wrapped in MaterialApp with the theme.
    // We use AppThemePreset.minimal to ensure ChinguTheme extension is present.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.minimal),
        home: const UserDetailScreen(),
      ),
    );

    // Verify that the PopupMenuButton (report button) is present.
    // The report button uses Icons.more_horiz_rounded
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);

    // Open the popup menu
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    // Verify "舉報用戶" item is visible
    expect(find.text('舉報用戶'), findsOneWidget);
  });
}
