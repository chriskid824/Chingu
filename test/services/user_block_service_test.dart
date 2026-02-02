import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  const String userId1 = 'user1';
  const String userId2 = 'user2';
  const String userId3 = 'user3';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser adds a block record', () async {
      await userBlockService.blockUser(userId1, userId2);

      final snapshot = await fakeFirestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['blockerId'], userId1);
      expect(snapshot.docs.first['blockedId'], userId2);
    });

    test('blockUser does not add duplicate block record', () async {
      await userBlockService.blockUser(userId1, userId2);
      await userBlockService.blockUser(userId1, userId2);

      final snapshot = await fakeFirestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
    });

    test('unblockUser removes the block record', () async {
      await userBlockService.blockUser(userId1, userId2);
      await userBlockService.unblockUser(userId1, userId2);

      final snapshot = await fakeFirestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 0);
    });

    test('getBlockedUserIds returns list of blocked users', () async {
      await userBlockService.blockUser(userId1, userId2);
      await userBlockService.blockUser(userId1, userId3);

      final blockedIds = await userBlockService.getBlockedUserIds(userId1);
      expect(blockedIds, containsAll([userId2, userId3]));
      expect(blockedIds.length, 2);
    });

    test('getUsersWhoBlocked returns list of users who blocked me', () async {
      await userBlockService.blockUser(userId2, userId1);
      await userBlockService.blockUser(userId3, userId1);

      final blockers = await userBlockService.getUsersWhoBlocked(userId1);
      expect(blockers, containsAll([userId2, userId3]));
      expect(blockers.length, 2);
    });

    test('getAllExcludedUserIds returns combined list', () async {
      // User1 blocks User2
      await userBlockService.blockUser(userId1, userId2);
      // User3 blocks User1
      await userBlockService.blockUser(userId3, userId1);

      final excludedIds = await userBlockService.getAllExcludedUserIds(userId1);
      expect(excludedIds, containsAll([userId2, userId3]));
      expect(excludedIds.length, 2);
    });

    test('isUserBlocked returns correct status', () async {
      await userBlockService.blockUser(userId1, userId2);

      expect(await userBlockService.isUserBlocked(userId1, userId2), true);
      expect(await userBlockService.isUserBlocked(userId1, userId3), false);
    });
  });
}
