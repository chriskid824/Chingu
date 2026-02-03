import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  const currentUserId = 'current_user';
  const targetUserId = 'target_user';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser should add user to blocked list', () async {
      await userBlockService.blockUser(currentUserId, targetUserId);

      final blockedDocs = await fakeFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .get();

      expect(blockedDocs.docs.length, 1);
      expect(blockedDocs.docs.first.id, targetUserId);
    });

    test('unblockUser should remove user from blocked list', () async {
      // Arrange
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Act
      await userBlockService.unblockUser(currentUserId, targetUserId);

      // Assert
      final blockedDocs = await fakeFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .get();

      expect(blockedDocs.docs.length, 0);
    });

    test('getBlockedUserIds should return list of blocked IDs', () async {
      // Arrange
      await userBlockService.blockUser(currentUserId, targetUserId);
      await userBlockService.blockUser(currentUserId, 'another_user');

      // Act
      final blockedIds =
          await userBlockService.getBlockedUserIds(currentUserId);

      // Assert
      expect(blockedIds.length, 2);
      expect(blockedIds, containsAll([targetUserId, 'another_user']));
    });

    test('isUserBlocked should return correct status', () async {
      // Arrange
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Act
      final isBlocked =
          await userBlockService.isUserBlocked(currentUserId, targetUserId);
      final isNotBlocked =
          await userBlockService.isUserBlocked(currentUserId, 'unknown');

      // Assert
      expect(isBlocked, true);
      expect(isNotBlocked, false);
    });
  });
}
