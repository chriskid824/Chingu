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
    const currentUserId = 'user1';
    const blockedUserId = 'user2';

    test('blockUser should add user to blocked list', () async {
      await userBlockService.blockUser(currentUserId, blockedUserId);

      final isBlocked = await userBlockService.isBlocked(currentUserId, blockedUserId);
      expect(isBlocked, isTrue);

      final blockedIds = await userBlockService.getBlockedUserIds(currentUserId);
      expect(blockedIds, contains(blockedUserId));
    });

    test('unblockUser should remove user from blocked list', () async {
      // First block
      await userBlockService.blockUser(currentUserId, blockedUserId);

      // Then unblock
      await userBlockService.unblockUser(currentUserId, blockedUserId);

      final isBlocked = await userBlockService.isBlocked(currentUserId, blockedUserId);
      expect(isBlocked, isFalse);

      final blockedIds = await userBlockService.getBlockedUserIds(currentUserId);
      expect(blockedIds, isNot(contains(blockedUserId)));
    });

    test('getBlockedUserIds should return all blocked users', () async {
      await userBlockService.blockUser(currentUserId, 'user2');
      await userBlockService.blockUser(currentUserId, 'user3');

      final blockedIds = await userBlockService.getBlockedUserIds(currentUserId);
      expect(blockedIds.length, 2);
      expect(blockedIds, containsAll(['user2', 'user3']));
    });
  });
}
