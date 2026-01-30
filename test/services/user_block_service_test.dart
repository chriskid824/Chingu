import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  const String currentUserId = 'user_1';
  const String targetUserId = 'user_2';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser should add user to blocked collection', () async {
      await userBlockService.blockUser(currentUserId, targetUserId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();

      expect(doc.exists, true);
    });

    test('isBlocked should return true for blocked user', () async {
      await userBlockService.blockUser(currentUserId, targetUserId);
      final isBlocked = await userBlockService.isBlocked(currentUserId, targetUserId);
      expect(isBlocked, true);
    });

    test('isBlocked should return false for non-blocked user', () async {
      final isBlocked = await userBlockService.isBlocked(currentUserId, 'user_3');
      expect(isBlocked, false);
    });

    test('unblockUser should remove user from blocked collection', () async {
      // First block
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Then unblock
      await userBlockService.unblockUser(currentUserId, targetUserId);

      final doc = await fakeFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();

      expect(doc.exists, false);
    });

    test('getBlockedUserIds should return list of blocked users', () async {
      await userBlockService.blockUser(currentUserId, 'user_a');
      await userBlockService.blockUser(currentUserId, 'user_b');

      final blockedIds = await userBlockService.getBlockedUserIds(currentUserId);

      expect(blockedIds, containsAll(['user_a', 'user_b']));
      expect(blockedIds.length, 2);
    });
  });
}
