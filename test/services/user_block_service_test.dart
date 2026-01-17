import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore firestore;
    late UserBlockService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = UserBlockService(firestore: firestore);
    });

    test('blockUser adds a block record', () async {
      await service.blockUser('user1', 'user2');

      final isBlocked = await service.isBlocked('user1', 'user2');
      expect(isBlocked, true);
    });

    test('blockUser does not duplicate block', () async {
      await service.blockUser('user1', 'user2');
      await service.blockUser('user1', 'user2');

      final docs = await firestore.collection('user_blocks').get();
      expect(docs.docs.length, 1);
    });

    test('unblockUser removes block record', () async {
      await service.blockUser('user1', 'user2');
      await service.unblockUser('user1', 'user2');

      final isBlocked = await service.isBlocked('user1', 'user2');
      expect(isBlocked, false);
    });

    test('getBlockedUserIds returns correct list', () async {
      await service.blockUser('user1', 'user2');
      await service.blockUser('user1', 'user3');
      await service.blockUser('user2', 'user3');

      final blocked = await service.getBlockedUserIds('user1');
      expect(blocked, containsAll(['user2', 'user3']));
      expect(blocked.length, 2);
    });

    test('getBlockedByIds returns correct list', () async {
      await service.blockUser('user1', 'user2');
      await service.blockUser('user3', 'user2');

      final blockedBy = await service.getBlockedByIds('user2');
      expect(blockedBy, containsAll(['user1', 'user3']));
      expect(blockedBy.length, 2);
    });
  });
}
