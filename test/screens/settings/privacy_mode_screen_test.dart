import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:chingu/screens/settings/privacy_mode_screen.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';

// Manual mock
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _userModel;

  @override
  UserModel? get userModel => _userModel;

  void setUserModel(UserModel user) {
    _userModel = user;
    notifyListeners();
  }

  @override
  Future<bool> updateUserData(Map<String, dynamic> data) async {
    if (_userModel != null) {
      // Simulate update locally
      bool isOnlineStatusHidden = _userModel!.isOnlineStatusHidden;
      bool isLastSeenHidden = _userModel!.isLastSeenHidden;

      if (data.containsKey('isOnlineStatusHidden')) {
        isOnlineStatusHidden = data['isOnlineStatusHidden'];
      }
      if (data.containsKey('isLastSeenHidden')) {
        isLastSeenHidden = data['isLastSeenHidden'];
      }

      _userModel = _userModel!.copyWith(
        isOnlineStatusHidden: isOnlineStatusHidden,
        isLastSeenHidden: isLastSeenHidden,
      );
      notifyListeners();
      return true;
    }
    return false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('PrivacyModeScreen displays and toggles settings', (WidgetTester tester) async {
    final mockAuthProvider = MockAuthProvider();
    final user = UserModel(
      uid: 'test_uid',
      name: 'Test User',
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
      isOnlineStatusHidden: false,
      isLastSeenHidden: false,
    );
    mockAuthProvider.setUserModel(user);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>.value(
          value: mockAuthProvider,
          child: const PrivacyModeScreen(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('隱藏在線狀態'), findsOneWidget);
    expect(find.text('隱藏最後上線時間'), findsOneWidget);

    // Check switches are off (default)
    expect(find.byWidgetPredicate((widget) => widget is Switch && widget.value == false), findsNWidgets(2));

    // Tap the "Hide Online Status" tile
    await tester.tap(find.text('隱藏在線狀態'));
    await tester.pump(); // Rebuild

    // Verify model updated
    expect(mockAuthProvider.userModel!.isOnlineStatusHidden, true);
    // Verify UI updated
    expect(find.byWidgetPredicate((widget) => widget is Switch && widget.value == true), findsOneWidget);

    // Tap the "Hide Last Seen" tile
    await tester.tap(find.text('隱藏最後上線時間'));
    await tester.pump(); // Rebuild

    // Verify model updated
    expect(mockAuthProvider.userModel!.isLastSeenHidden, true);
    // Verify UI updated (both true now)
    expect(find.byWidgetPredicate((widget) => widget is Switch && widget.value == true), findsNWidgets(2));
  });
}
