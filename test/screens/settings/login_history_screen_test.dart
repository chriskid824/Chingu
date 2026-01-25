import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:chingu/screens/settings/login_history_screen.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/login_history_model.dart';

class MockLoginHistoryService extends Mock implements LoginHistoryService {
  @override
  Stream<List<LoginHistoryModel>> getLoginHistory(String? userId) {
      return super.noSuchMethod(
        Invocation.method(#getLoginHistory, [userId]),
        returnValue: Stream.value(<LoginHistoryModel>[]),
        returnValueForMissingStub: Stream.value(<LoginHistoryModel>[]),
      ) as Stream<List<LoginHistoryModel>>;
  }
}

// A partial mock of AuthProvider that extends ChangeNotifier
class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  final String? _uid;

  FakeAuthProvider({String? uid}) : _uid = uid;

  @override
  String? get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Just return null for everything else
    return null;
  }
}

void main() {
  testWidgets('LoginHistoryScreen shows history list', (WidgetTester tester) async {
    final mockService = MockLoginHistoryService();

    final history = [
      LoginHistoryModel(
        id: '1',
        userId: 'user1',
        timestamp: DateTime(2023, 1, 1, 12, 0),
        deviceName: 'Test Device',
        osVersion: 'Test OS',
        location: 'Test City',
      ),
    ];

    when(mockService.getLoginHistory(any)).thenAnswer((_) => Stream.value(history));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(uid: 'user1'),
            ),
          ],
          child: LoginHistoryScreen(service: mockService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('登入紀錄'), findsWidgets); // AppBar title
    expect(find.text('Test Device'), findsOneWidget);
    expect(find.text('Test OS'), findsOneWidget);
    expect(find.text('Test City'), findsOneWidget);
    expect(find.text('2023/01/01 12:00'), findsOneWidget);
  });

  testWidgets('LoginHistoryScreen shows empty state', (WidgetTester tester) async {
    final mockService = MockLoginHistoryService();

    when(mockService.getLoginHistory(any)).thenAnswer((_) => Stream.value([]));

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(uid: 'user1'),
            ),
          ],
          child: LoginHistoryScreen(service: mockService),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('尚無登入紀錄'), findsOneWidget);
  });
}
