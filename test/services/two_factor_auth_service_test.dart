import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/two_factor_auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';

// Manual Mock for FirestoreService to avoid build_runner dependency and initialization issues
class MockFirestoreService implements FirestoreService {
  Map<String, dynamic>? lastUpdatedData;
  String? lastUpdatedUid;

  @override
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    lastUpdatedUid = uid;
    lastUpdatedData = data;
  }

  // Implement other methods as needed, throwing UnimplementedError
  @override
  Future<void> createUser(UserModel userModel) => throw UnimplementedError();

  @override
  Future<void> deleteUser(String uid) => throw UnimplementedError();

  @override
  Future<List<UserModel>> getBatchUsers(List<String> uids) => throw UnimplementedError();

  @override
  Future<UserModel?> getUser(String uid) => throw UnimplementedError();

  @override
  Stream<UserModel?> getUserStream(String uid) => throw UnimplementedError();

  @override
  Future<List<UserModel>> queryMatchingUsers({required String city, int? budgetRange, String? gender, int? minAge, int? maxAge, int limit = 20}) => throw UnimplementedError();

  @override
  Future<List<UserModel>> searchUsers(String searchTerm, {int limit = 20}) => throw UnimplementedError();

  @override
  Future<void> submitUserReport({required String reporterId, required String reportedUserId, required String reason, required String description}) => throw UnimplementedError();

  @override
  Future<void> updateLastLogin(String uid) => throw UnimplementedError();

  @override
  Future<void> updateUserRating(String uid, double newRating) => throw UnimplementedError();

  @override
  Future<void> updateUserStats(String uid, {int? totalDinners, int? totalMatches}) => throw UnimplementedError();

  @override
  Future<bool> userExists(String uid) => throw UnimplementedError();
}

void main() {
  group('TwoFactorAuthService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirestoreService mockFirestoreService;
    late TwoFactorAuthService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockFirestoreService = MockFirestoreService();
      service = TwoFactorAuthService(
        firestore: fakeFirestore,
        firestoreService: mockFirestoreService,
      );
    });

    test('sendVerificationCode creates a document with correct fields', () async {
      await service.sendVerificationCode(
        target: 'test@example.com',
        method: 'email',
        uid: 'user123',
      );

      final snapshot = await fakeFirestore
          .collection('two_factor_codes')
          .doc('test@example.com')
          .get();

      expect(snapshot.exists, isTrue);
      final data = snapshot.data()!;
      expect(data['method'], 'email');
      expect(data['uid'], 'user123');
      expect(data['attempts'], 0);
      expect(data['code'], isNotNull);
      expect((data['code'] as String).length, 6);
      expect(data['expiresAt'], isA<Timestamp>());
    });

    test('sendVerificationCode throws ArgumentError if target is empty', () async {
      expect(
        () => service.sendVerificationCode(target: '', method: 'email'),
        throwsArgumentError,
      );
    });

    test('sendVerificationCode throws ArgumentError if method is invalid', () async {
      expect(
        () => service.sendVerificationCode(target: 'test@example.com', method: 'pigeon'),
        throwsArgumentError,
      );
    });

    test('verifyCode returns true for correct code', () async {
      // Setup
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc('test@example.com').set({
        'code': '123456',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute
      final result = await service.verifyCode('test@example.com', '123456');

      // Verify
      expect(result, isTrue);
      final snapshot = await fakeFirestore.collection('two_factor_codes').doc('test@example.com').get();
      expect(snapshot.exists, isFalse); // Should be deleted
    });

    test('verifyCode returns false and increments attempts for incorrect code', () async {
      // Setup
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc('test@example.com').set({
        'code': '123456',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute
      final result = await service.verifyCode('test@example.com', '654321');

      // Verify
      expect(result, isFalse);
      final snapshot = await fakeFirestore.collection('two_factor_codes').doc('test@example.com').get();
      expect(snapshot.exists, isTrue);
      expect(snapshot.data()!['attempts'], 1);
    });

    test('verifyCode throws exception if code is expired', () async {
       // Setup
      final expiresAt = DateTime.now().subtract(const Duration(minutes: 1)); // Expired
      await fakeFirestore.collection('two_factor_codes').doc('test@example.com').set({
        'code': '123456',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
      });

      // Execute & Verify
      expect(
        () => service.verifyCode('test@example.com', '123456'),
        throwsException,
      );
    });

    test('verifyCode throws exception if attempts exceeded', () async {
       // Setup
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));
      await fakeFirestore.collection('two_factor_codes').doc('test@example.com').set({
        'code': '123456',
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 5,
      });

      // Execute & Verify
      expect(
        () => service.verifyCode('test@example.com', '123456'),
        throwsException,
      );
    });

    test('enableTwoFactor updates user correctly', () async {
      await service.enableTwoFactor('user123', 'sms', phoneNumber: '+1234567890');

      expect(mockFirestoreService.lastUpdatedUid, 'user123');
      expect(mockFirestoreService.lastUpdatedData!['isTwoFactorEnabled'], true);
      expect(mockFirestoreService.lastUpdatedData!['twoFactorMethod'], 'sms');
      expect(mockFirestoreService.lastUpdatedData!['phoneNumber'], '+1234567890');
    });

     test('enableTwoFactor throws if sms method has no phone number', () async {
      expect(
        () => service.enableTwoFactor('user123', 'sms'),
        throwsException,
      );
    });

    test('disableTwoFactor updates user correctly', () async {
      await service.disableTwoFactor('user123');

      expect(mockFirestoreService.lastUpdatedUid, 'user123');
      expect(mockFirestoreService.lastUpdatedData!['isTwoFactorEnabled'], false);
    });
  });
}
