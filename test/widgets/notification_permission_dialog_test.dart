import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/widgets/notification_permission_dialog.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/notification_model.dart';

// Fake service
class FakeRichNotificationService implements RichNotificationService {
  bool requestPermissionsCalled = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCalled = true;
    return true;
  }

  @override
  Future<void> showNotification(NotificationModel notification) async {}
}

void main() {
  testWidgets('NotificationPermissionDialog shows correctly and handles tap', (WidgetTester tester) async {
    // Setup Mock
    final fakeService = FakeRichNotificationService();
    RichNotificationService.mockInstance = fakeService;

    // Build app with theme
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => NotificationPermissionDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open Dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify content
    expect(find.text('不要錯過配對通知！'), findsOneWidget);
    expect(find.text('開啟通知以便第一時間收到配對成功、新訊息以及活動提醒。'), findsOneWidget);
    expect(find.text('開啟通知'), findsOneWidget);
    expect(find.text('暫時不要'), findsOneWidget);
    expect(find.byType(GradientButton), findsOneWidget);

    // Tap "開啟通知"
    await tester.tap(find.text('開啟通知'));
    await tester.pumpAndSettle(); // Dialog should close

    // Verify service called
    expect(fakeService.requestPermissionsCalled, isTrue);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });

  testWidgets('NotificationPermissionDialog closes on "暫時不要"', (WidgetTester tester) async {
    final fakeService = FakeRichNotificationService();
    RichNotificationService.mockInstance = fakeService;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(AppThemePreset.orange),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => NotificationPermissionDialog.show(context),
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('暫時不要'));
    await tester.pumpAndSettle();

    expect(fakeService.requestPermissionsCalled, isFalse);
    expect(find.byType(NotificationPermissionDialog), findsNothing);
  });
}
