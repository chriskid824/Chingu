import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('NotificationPermissionDialog renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
           ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: Consumer<ThemeController>(
          builder: (context, controller, _) {
            return MaterialApp(
              theme: controller.theme,
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const NotificationPermissionDialog(),
                        );
                      },
                      child: const Text('Show Dialog'),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );

    // Verify that the dialog is not shown initially
    expect(find.text('開啟通知'), findsNothing);

    // Tap the button to show dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify content
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.textContaining('不錯過任何晚餐配對通知'), findsOneWidget);
    expect(find.text('稍後'), findsOneWidget);
    expect(find.text('開啟'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);
  });
}
