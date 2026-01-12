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

      final snapshot = await firestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['blockerId'], 'user1');
      expect(snapshot.docs.first['blockedId'], 'user2');
    });

    test('blockUser prevents duplicates', () async {
      await service.blockUser('user1', 'user2');
      await service.blockUser('user1', 'user2');

      final snapshot = await firestore.collection('user_blocks').get();
      expect(snapshot.docs.length, 1);
    });

    test('unblockUser removes the block record', () async {
      await service.blockUser('user1', 'user2');
      await service.unblockUser('user1', 'user2');

      final snapshot = await firestore.collection('user_blocks').get();
      expect(snapshot.docs.isEmpty, true);
    });

    test('isBlocked returns correct status', () async {
      await service.blockUser('user1', 'user2');

      expect(await service.isBlocked('user1', 'user2'), true);
      expect(await service.isBlocked('user1', 'user3'), false);
    });

    test('getBlockedAndBlockedByUserIds returns bidirectional blocked ids', () async {
      // user1 blocks user2
      await service.blockUser('user1', 'user2');
      // user3 blocks user1
      await service.blockUser('user3', 'user1');
      // user1 blocks user4
      await service.blockUser('user1', 'user4');

      final ids = await service.getBlockedAndBlockedByUserIds('user1');

      expect(ids.contains('user2'), true); // I blocked
      expect(ids.contains('user3'), true); // blocked me
      expect(ids.contains('user4'), true); // I blocked
      expect(ids.length, 3);
    });
  });
}
