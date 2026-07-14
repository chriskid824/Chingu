import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NotificationPermissionDialog shows correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    // Tap to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('開啟通知，不錯過任何緣分'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('暫不開啟'), findsOneWidget);
  });

  testWidgets('Tapping Allow returns true', (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle();

    expect(result, true);
  });

  testWidgets('Tapping Deny returns false', (WidgetTester tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await NotificationPermissionDialog.show(context);
              },
              child: const Text('Show Dialog'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('暫不開啟'));
    await tester.pumpAndSettle();

    expect(result, false);
  });
}
