import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserBlockService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = UserBlockService(firestore: fakeFirestore);
    });

    test('blockUser adds a document to user_blocks with correct ID', () async {
      await service.blockUser('user1', 'user2');

      final snapshot = await fakeFirestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'user1_user2');
      expect(snapshot.docs.first.data()['blockerId'], 'user1');
      expect(snapshot.docs.first.data()['blockedId'], 'user2');
    });

    test('blockUser overwrites existing block (idempotent)', () async {
      await service.blockUser('user1', 'user2');
      await service.blockUser('user1', 'user2');

      final snapshot = await fakeFirestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.id, 'user1_user2');
    });

    test('isBlocked returns correct status', () async {
      await service.blockUser('user1', 'user2');

      expect(await service.isBlocked('user1', 'user2'), true);
      expect(await service.isBlocked('user2', 'user1'), false);
    });

    test('unblockUser removes the block', () async {
      await service.blockUser('user1', 'user2');
      await service.unblockUser('user1', 'user2');

      expect(await service.isBlocked('user1', 'user2'), false);
    });

    test('getBlockedUserIds returns users blocked by me', () async {
      await service.blockUser('me', 'user1');
      await service.blockUser('me', 'user2');
      await service.blockUser('other', 'user3');

      final blocked = await service.getBlockedUserIds('me');
      expect(blocked.length, 2);
      expect(blocked, containsAll(['user1', 'user2']));
    });

    test('getBlockedByList returns users who blocked me', () async {
      await service.blockUser('user1', 'me');
      await service.blockUser('user2', 'me');
      await service.blockUser('user3', 'other');

      final blockedBy = await service.getBlockedByList('me');
      expect(blockedBy.length, 2);
      expect(blockedBy, containsAll(['user1', 'user2']));
    });

    test('getExcludedUserIds returns union of blocked and blockedBy', () async {
      await service.blockUser('me', 'user1'); // I blocked user1
      await service.blockUser('user2', 'me'); // user2 blocked me
      await service.blockUser('me', 'user2'); // I blocked user2 (mutual)

      final excluded = await service.getExcludedUserIds('me');
      expect(excluded.length, 2);
      expect(excluded, containsAll(['user1', 'user2']));
    });
  });
}
