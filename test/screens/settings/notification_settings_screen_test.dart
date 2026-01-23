import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chingu/screens/settings/notification_settings_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock UserModel
final mockUser = UserModel(
  uid: 'test_uid',
  name: 'Test User',
  email: 'test@example.com',
  age: 25,
  gender: 'male',
  job: 'Dev',
  interests: ['coding'],
  country: 'Taiwan',
  city: 'Taipei',
  district: 'Xinyi',
  preferredMatchType: 'any',
  minAge: 18,
  maxAge: 30,
  budgetRange: 1,
  createdAt: DateTime.now(),
  lastLogin: DateTime.now(),
  enableMatchNotifications: true,
  enableMessageNotifications: false,
  enableEventNotifications: true,
);

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _userModel = mockUser;
  Map<String, dynamic>? lastUpdateData;

  @override
  UserModel? get userModel => _userModel;

  @override
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    lastUpdateData = data;
    // Update local model to reflect changes
    _userModel = _userModel?.copyWith(
      enableMatchNotifications: data['enableMatchNotifications'],
      enableMessageNotifications: data['enableMessageNotifications'],
      enableEventNotifications: data['enableEventNotifications'],
    );
    notifyListeners();
    return true;
  }

  // Implement other required members with dummies/errors
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('NotificationSettingsScreen displays switches with correct initial values', (WidgetTester tester) async {
    final authProvider = FakeAuthProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const NotificationSettingsScreen(),
        ),
      ),
    );

    // Verify switches are present
    expect(find.text('啟用配對通知'), findsOneWidget);
    expect(find.text('啟用訊息通知'), findsOneWidget);
    expect(find.text('啟用活動通知'), findsOneWidget);

    // Verify initial values
    final matchTileFinder = find.widgetWithText(SwitchListTile, '啟用配對通知');
    final matchTile = tester.widget<SwitchListTile>(matchTileFinder);
    expect(matchTile.value, true);

    final messageTileFinder = find.widgetWithText(SwitchListTile, '啟用訊息通知');
    final messageTile = tester.widget<SwitchListTile>(messageTileFinder);
    expect(messageTile.value, false);

    final eventTileFinder = find.widgetWithText(SwitchListTile, '啟用活動通知');
    final eventTile = tester.widget<SwitchListTile>(eventTileFinder);
    expect(eventTile.value, true);
  });

  testWidgets('Toggling switch calls updateUserData', (WidgetTester tester) async {
    final authProvider = FakeAuthProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
          child: const NotificationSettingsScreen(),
        ),
      ),
    );

    // Toggle Message Notification from false to true
    final messageTileFinder = find.widgetWithText(SwitchListTile, '啟用訊息通知');
    await tester.tap(messageTileFinder);
    await tester.pump();

    // Verify updateUserData was called
    expect(authProvider.lastUpdateData, isNotNull);
    expect(authProvider.lastUpdateData!['enableMessageNotifications'], true);

    // Verify UI updated
    final messageTile = tester.widget<SwitchListTile>(messageTileFinder);
    expect(messageTile.value, true);
  });
}
