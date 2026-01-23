import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/user_block_service.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserBlockService userBlockService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userBlockService = UserBlockService(firestore: fakeFirestore);
    });

    test('blockUser should create a block document', () async {
      const blockerId = 'user1';
      const blockedId = 'user2';

      await userBlockService.blockUser(blockerId, blockedId);

      final doc = await fakeFirestore
          .collection('user_blocks')
          .doc('${blockerId}_$blockedId')
          .get();

      expect(doc.exists, isTrue);
      expect(doc['blockerId'], blockerId);
      expect(doc['blockedId'], blockedId);
    });

    test('unblockUser should delete the block document', () async {
      const blockerId = 'user1';
      const blockedId = 'user2';

      await userBlockService.blockUser(blockerId, blockedId);
      await userBlockService.unblockUser(blockerId, blockedId);

      final doc = await fakeFirestore
          .collection('user_blocks')
          .doc('${blockerId}_$blockedId')
          .get();

      expect(doc.exists, isFalse);
    });

    test('getBlockedIds should return users I blocked and users who blocked me', () async {
      const myId = 'me';
      const userABlockedMe = 'userA';
      const userIBlockedB = 'userB';
      const randomUser = 'userC';

      // userA blocks me
      await userBlockService.blockUser(userABlockedMe, myId);
      // I block userB
      await userBlockService.blockUser(myId, userIBlockedB);
      // Random block unrelated to me
      await userBlockService.blockUser(randomUser, 'userD');

      final blockedIds = await userBlockService.getBlockedIds(myId);

      expect(blockedIds, contains(userABlockedMe));
      expect(blockedIds, contains(userIBlockedB));
      expect(blockedIds, isNot(contains(randomUser)));
      expect(blockedIds.length, 2);
    });

    test('isBlocked should return true if either party blocked the other', () async {
      const user1 = 'user1';
      const user2 = 'user2';

      // No block
      expect(await userBlockService.isBlocked(user1, user2), isFalse);

      // user1 blocks user2
      await userBlockService.blockUser(user1, user2);
      expect(await userBlockService.isBlocked(user1, user2), isTrue);
      expect(await userBlockService.isBlocked(user2, user1), isTrue); // Check reverse

      // Unblock
      await userBlockService.unblockUser(user1, user2);
      expect(await userBlockService.isBlocked(user1, user2), isFalse);
    });
  });
}
