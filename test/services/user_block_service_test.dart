import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore firestore;
    late UserBlockService userBlockService;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      userBlockService = UserBlockService(firestore: firestore);
    });

    test('blockUser creates a block document', () async {
      await userBlockService.blockUser('user1', 'user2');

      final snapshot = await firestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'user1_user2');
      expect(snapshot.docs.first.data()['blockerId'], 'user1');
      expect(snapshot.docs.first.data()['blockedId'], 'user2');
    });

    test('unblockUser removes the block document', () async {
      await userBlockService.blockUser('user1', 'user2');
      await userBlockService.unblockUser('user1', 'user2');

      final snapshot = await firestore.collection('user_blocks').get();
      expect(snapshot.docs.isEmpty, true);
    });

    test('getBlockedUserIds returns correct list', () async {
      await userBlockService.blockUser('user1', 'user2');
      await userBlockService.blockUser('user1', 'user3');
      await userBlockService.blockUser('user2', 'user1'); // user2 blocked user1

      final blocked = await userBlockService.getBlockedUserIds('user1');
      expect(blocked.length, 2);
      expect(blocked, containsAll(['user2', 'user3']));
    });

    test('getBlockedByUserIds returns correct list', () async {
      await userBlockService.blockUser('user2', 'user1');
      await userBlockService.blockUser('user3', 'user1');
      await userBlockService.blockUser('user1', 'user2');

      final blockedBy = await userBlockService.getBlockedByUserIds('user1');
      expect(blockedBy.length, 2);
      expect(blockedBy, containsAll(['user2', 'user3']));
    });

    test('isBlocked returns correct status', () async {
      await userBlockService.blockUser('user1', 'user2');

      expect(await userBlockService.isBlocked('user1', 'user2'), true);
      expect(await userBlockService.isBlocked('user2', 'user1'), false);
    });
  });
}
