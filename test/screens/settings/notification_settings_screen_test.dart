import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/screens/settings/notification_settings_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/notification_preferences.dart';

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  @override
  UserModel? get userModel => _userModel;

  UserModel? _userModel;

  void setUserModel(UserModel? user) {
    _userModel = user;
  }

  @override
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    return true;
  }
}

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
  });

  Widget createScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: mockAuthProvider,
        child: const NotificationSettingsScreen(),
      ),
    );
  }

  testWidgets('NotificationSettingsScreen shows loading when user is null', (WidgetTester tester) async {
    mockAuthProvider.setUserModel(null);
    await tester.pumpWidget(createScreen());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('NotificationSettingsScreen shows switches with correct values', (WidgetTester tester) async {
    final user = UserModel(
      uid: '123',
      name: 'Test',
      email: 'test@example.com',
      age: 25,
      gender: 'male',
      job: 'Dev',
      interests: [],
      country: 'TW',
      city: 'Taipei',
      district: 'Xinyi',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 30,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      notificationPreferences: const NotificationPreferences(
        matchEnabled: true,
        messageEnabled: false,
        eventEnabled: true,
      ),
    );
    mockAuthProvider.setUserModel(user);

    await tester.pumpWidget(createScreen());

    // Check for SwitchListTile
    expect(find.byType(SwitchListTile), findsNWidgets(3));

    // Check titles
    expect(find.text('配對更新'), findsOneWidget);
    expect(find.text('新訊息'), findsOneWidget);
    expect(find.text('活動更新'), findsOneWidget);

    // Check values
    final switches = tester.widgetList<SwitchListTile>(find.byType(SwitchListTile));
    expect(switches.elementAt(0).value, isTrue); // Match
    expect(switches.elementAt(1).value, isFalse); // Message
    expect(switches.elementAt(2).value, isTrue); // Event
  });
}
