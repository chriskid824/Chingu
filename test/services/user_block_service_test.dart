import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserBlockService userBlockService;
    late UserModel user1;
    late UserModel user2;

    setUp(() async {
      fakeFirestore = FakeFirebaseFirestore();
      userBlockService = UserBlockService(firestore: fakeFirestore);

      user1 = UserModel(
        uid: 'user1',
        name: 'User One',
        email: 'user1@example.com',
        age: 25,
        gender: 'male',
        job: 'Engineer',
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
      );

      user2 = UserModel(
        uid: 'user2',
        name: 'User Two',
        email: 'user2@example.com',
        age: 24,
        gender: 'female',
        job: 'Designer',
        interests: ['art'],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Daan',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
      );

      await fakeFirestore.collection('users').doc(user1.uid).set(user1.toMap());
      await fakeFirestore.collection('users').doc(user2.uid).set(user2.toMap());
    });

    test('blockUser adds targetUserId to blockedUsers list', () async {
      await userBlockService.blockUser(user1.uid, user2.uid);

      final user1Doc =
          await fakeFirestore.collection('users').doc(user1.uid).get();
      final blockedUsers =
          List<String>.from(user1Doc.data()!['blockedUsers'] ?? []);

      expect(blockedUsers, contains(user2.uid));
    });

    test('unblockUser removes targetUserId from blockedUsers list', () async {
      // First block
      await userBlockService.blockUser(user1.uid, user2.uid);

      // Then unblock
      await userBlockService.unblockUser(user1.uid, user2.uid);

      final user1Doc =
          await fakeFirestore.collection('users').doc(user1.uid).get();
      final blockedUsers =
          List<String>.from(user1Doc.data()!['blockedUsers'] ?? []);

      expect(blockedUsers, isNot(contains(user2.uid)));
    });

    test('isBlocked returns true if user is blocked locally', () {
      final userWithBlock = user1.copyWith(blockedUsers: [user2.uid]);
      expect(userBlockService.isBlocked(userWithBlock, user2.uid), isTrue);
      expect(userBlockService.isBlocked(userWithBlock, 'other'), isFalse);
    });

    test('isBlockedBy checks if the other user blocked current user', () async {
       // user2 blocks user1
      await fakeFirestore.collection('users').doc(user2.uid).update({
        'blockedUsers': [user1.uid]
      });

      final isBlocked = await userBlockService.isBlockedBy(user1.uid, user2.uid);
      expect(isBlocked, isTrue);

      final isBlockedReverse = await userBlockService.isBlockedBy(user2.uid, user1.uid);
      expect(isBlockedReverse, isFalse);
    });
  });
}
