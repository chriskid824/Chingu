import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late UserBlockService userBlockService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser creates a block document', () async {
      await userBlockService.blockUser('user1', 'user2');

      final doc = await fakeFirestore
          .collection('user_blocks')
          .doc('user1_user2')
          .get();

      expect(doc.exists, true);
      expect(doc.data()?['blockerId'], 'user1');
      expect(doc.data()?['blockedId'], 'user2');
    });

    test('unblockUser deletes the block document', () async {
      await userBlockService.blockUser('user1', 'user2');
      await userBlockService.unblockUser('user1', 'user2');

      final doc = await fakeFirestore
          .collection('user_blocks')
          .doc('user1_user2')
          .get();

      expect(doc.exists, false);
    });

    test('isBlocked returns correct status', () async {
      await userBlockService.blockUser('user1', 'user2');

      expect(await userBlockService.isBlocked('user1', 'user2'), true);
      expect(await userBlockService.isBlocked('user1', 'user3'), false);
    });

    test('getBlockedUserIds returns list of users I blocked', () async {
      await userBlockService.blockUser('user1', 'user2');
      await userBlockService.blockUser('user1', 'user3');
      await userBlockService.blockUser('user2', 'user1'); // blocked by others

      final blocked = await userBlockService.getBlockedUserIds('user1');

      expect(blocked.length, 2);
      expect(blocked, containsAll(['user2', 'user3']));
    });

    test('getIdsThatBlockedUser returns list of users who blocked me', () async {
      await userBlockService.blockUser('user2', 'user1');
      await userBlockService.blockUser('user3', 'user1');
      await userBlockService.blockUser('user1', 'user4'); // I blocked someone

      final blockedBy = await userBlockService.getIdsThatBlockedUser('user1');

      expect(blockedBy.length, 2);
      expect(blockedBy, containsAll(['user2', 'user3']));
    });

    test('getAllExcludedUserIds returns combined list', () async {
      await userBlockService.blockUser('user1', 'user2'); // I block 2
      await userBlockService.blockUser('user3', 'user1'); // 3 blocks me

      final all = await userBlockService.getAllExcludedUserIds('user1');

      expect(all.length, 2);
      expect(all, containsAll(['user2', 'user3']));
    });
  });
}
