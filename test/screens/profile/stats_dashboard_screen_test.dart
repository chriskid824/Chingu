import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/screens/profile/stats_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Manual Mock
class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  UserModel? _userModel;

  @override
  UserModel? get userModel => _userModel;

  void setUserModel(UserModel? user) {
    _userModel = user;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('StatsDashboardScreen displays user stats', (WidgetTester tester) async {
    final mockAuthProvider = MockAuthProvider();

    final user = UserModel(
      uid: 'test_uid',
      name: 'Test User',
      email: 'test@example.com',
      age: 25,
      gender: 'male',
      job: 'Developer',
      interests: [],
      country: 'Taiwan',
      city: 'Taipei',
      district: 'Xinyi',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 30,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      totalMatches: 15,
      totalDinners: 7,
      totalMessagesSent: 123,
      averageRating: 4.8,
    );

    mockAuthProvider.setUserModel(user);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: mockAuthProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.themeFor(AppThemePreset.minimal),
          home: const StatsDashboardScreen(),
        ),
      ),
    );

    // Pump to let animations finish (AnimatedCounter default is 1.5s)
    await tester.pumpAndSettle();

    // Verify stats are displayed
    expect(find.text('15'), findsWidgets); // Matches
    expect(find.text('7'), findsWidgets); // Dinners
    expect(find.text('123'), findsWidgets); // Messages
    expect(find.text('4.8'), findsWidgets); // Rating

    expect(find.text('配對次數'), findsOneWidget);
    expect(find.text('活動參與'), findsOneWidget);
    expect(find.text('聊天活躍度'), findsOneWidget);
  });
}
