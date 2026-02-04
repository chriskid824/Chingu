import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirestoreService])
import 'user_block_service_test.mocks.dart';

void main() {
  late UserBlockService userBlockService;
  late MockFirestoreService mockFirestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(
      firestore: fakeFirestore,
      firestoreService: mockFirestoreService,
    );
  });

  group('UserBlockService', () {
    test('blockUser should update blockedUserIds', () async {
      // Arrange
      const currentUserId = 'user1';
      const targetUserId = 'user2';
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUserIds': [],
      });

      // Act
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blocked = List<String>.from(doc.data()!['blockedUserIds']);
      expect(blocked, contains(targetUserId));
    });

    test('unblockUser should remove from blockedUserIds', () async {
      // Arrange
      const currentUserId = 'user1';
      const targetUserId = 'user2';
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUserIds': [targetUserId],
      });

      // Act
      await userBlockService.unblockUser(currentUserId, targetUserId);

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blocked = List<String>.from(doc.data()!['blockedUserIds']);
      expect(blocked, isNot(contains(targetUserId)));
    });

    test('isBlocked should return true if user is blocked', () async {
      // Arrange
      const currentUserId = 'user1';
      const targetUserId = 'user2';

      final user = UserModel(
        uid: currentUserId,
        name: 'User 1',
        email: 'test@test.com',
        age: 25,
        gender: 'male',
        job: 'dev',
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
        blockedUserIds: [targetUserId],
      );

      when(mockFirestoreService.getUser(currentUserId))
          .thenAnswer((_) async => user);

      // Act
      final result = await userBlockService.isBlocked(currentUserId, targetUserId);

      // Assert
      expect(result, true);
    });
  });
}
