import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser should add document to blocked_users subcollection', () async {
      await userBlockService.blockUser('user1', 'user2');

      final blockedDoc = await fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('blocked_users')
          .doc('user2')
          .get();

      expect(blockedDoc.exists, isTrue);
      expect(blockedDoc.data()?['uid'], 'user2');
    });

    test('unblockUser should remove document from blocked_users subcollection', () async {
      // Arrange
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('blocked_users')
          .doc('user2')
          .set({'uid': 'user2'});

      // Act
      await userBlockService.unblockUser('user1', 'user2');

      // Assert
      final blockedDoc = await fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('blocked_users')
          .doc('user2')
          .get();

      expect(blockedDoc.exists, isFalse);
    });

    test('isBlocked should return true if user is blocked', () async {
      await userBlockService.blockUser('user1', 'user2');

      final result = await userBlockService.isBlocked('user1', 'user2');
      expect(result, isTrue);
    });

    test('isBlocked should return false if user is not blocked', () async {
      final result = await userBlockService.isBlocked('user1', 'user2');
      expect(result, isFalse);
    });

    test('getBlockedUserIds should return list of blocked user IDs', () async {
      await userBlockService.blockUser('user1', 'user2');
      await userBlockService.blockUser('user1', 'user3');

      final result = await userBlockService.getBlockedUserIds('user1');
      expect(result, containsAll(['user2', 'user3']));
      expect(result.length, 2);
    });

    test('getBlockedByUserIds should return list of users who blocked me', () async {
      // user2 blocks user1
      await userBlockService.blockUser('user2', 'user1');
      // user3 blocks user1
      await userBlockService.blockUser('user3', 'user1');

      final result = await userBlockService.getBlockedByUserIds('user1');

      expect(result, containsAll(['user2', 'user3']));
      expect(result.length, 2);
    });
  });
}
