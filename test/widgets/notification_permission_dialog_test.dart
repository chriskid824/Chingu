import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('NotificationPermissionDialog shows correct content and handles clicks', (WidgetTester tester) async {
    bool onEnableCalled = false;
    bool onLaterCalled = false;

    // Use a real MaterialApp to provide Theme with ThemeController
    await tester.pumpWidget(
      MultiProvider(
        providers: [
           ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, themeController, _) {
            return MaterialApp(
              theme: themeController.theme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        NotificationPermissionDialog.show(
                          context,
                          onEnable: () => onEnableCalled = true,
                          onLater: () => onLaterCalled = true,
                        );
                      },
                      child: const Text('Show Dialog'),
                    ),
                  ),
                ),
              ),
            );
          }
        ),
      ),
    );

    // Initial state
    expect(find.text('Show Dialog'), findsOneWidget);

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog content
    // There are two '開啟通知': one title, one button
    expect(find.text('開啟通知'), findsNWidgets(2));
    expect(find.textContaining('不錯過任何重要訊息'), findsOneWidget);
    expect(find.text('稍後再說'), findsOneWidget);

    // Test "Later" button
    await tester.tap(find.text('稍後再說'));
    await tester.pumpAndSettle();
    expect(onLaterCalled, isTrue);
    expect(find.text('稍後再說'), findsNothing); // Dialog closed

    // Re-open dialog to test "Enable"
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Tap "Enable" button.
    // We target the ElevatedButton which contains the text '開啟通知'.
    final enableButtonFinder = find.widgetWithText(ElevatedButton, '開啟通知');
    await tester.tap(enableButtonFinder);
    await tester.pumpAndSettle();

    expect(onEnableCalled, isTrue);
    expect(find.text('稍後再說'), findsNothing); // Dialog closed
  });
}
