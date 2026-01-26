import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:async';

// Mock User
class MockUser extends Fake implements firebase_auth.User {
  @override
  String get uid => '123';
}

class MockAuthService extends Fake implements AuthService {
  final StreamController<firebase_auth.User?> _controller = StreamController<firebase_auth.User?>();

  @override
  Stream<firebase_auth.User?> get authStateChanges => _controller.stream;

  void emit(firebase_auth.User? user) {
    _controller.add(user);
  }
}

class MockFirestoreService extends Fake implements FirestoreService {
  UserModel? userToReturn;
  Map<String, dynamic>? lastUpdateData;

  @override
  Future<UserModel?> getUser(String uid) async {
    return userToReturn;
  }

  @override
  Future<void> updateLastLogin(String uid) async {
    // no-op
  }

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    lastUpdateData = data;
  }
}

void main() {
  test('toggleFavorite adds and removes favorite', () async {
    final mockAuthService = MockAuthService();
    final mockFirestoreService = MockFirestoreService();

    final user = UserModel(
      uid: '123',
      name: 'Test',
      email: 'test@test.com',
      age: 20,
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
      favorites: [],
    );

    mockFirestoreService.userToReturn = user;

    final provider = AuthProvider(
      authService: mockAuthService,
      firestoreService: mockFirestoreService,
    );

    // Trigger login
    mockAuthService.emit(MockUser());

    // Wait for async operations in listener
    await Future.delayed(const Duration(milliseconds: 100));

    expect(provider.userModel, isNotNull);
    expect(provider.userModel!.favorites, isEmpty);

    // Toggle favorite on '456'
    await provider.toggleFavorite('456');

    expect(provider.userModel!.favorites, contains('456'));
    expect(mockFirestoreService.lastUpdateData, isNotNull);
    expect(mockFirestoreService.lastUpdateData!['favorites'], contains('456'));

    // Toggle again to remove
    await provider.toggleFavorite('456');

    expect(provider.userModel!.favorites, isNot(contains('456')));
    expect(mockFirestoreService.lastUpdateData!['favorites'], isNot(contains('456')));
  });
}
