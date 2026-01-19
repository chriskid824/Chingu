import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  const currentUserId = 'user1';
  const targetUserId = 'user2';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    test('blockUser adds document to subcollection', () async {
      await userBlockService.blockUser(currentUserId, targetUserId, reason: 'spam');

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked_users')
          .doc(targetUserId)
          .get();

      expect(snapshot.exists, true);
      expect(snapshot.data()?['blockedUserId'], targetUserId);
      expect(snapshot.data()?['reason'], 'spam');
    });

    test('isBlocked returns true when user is blocked', () async {
      await userBlockService.blockUser(currentUserId, targetUserId);

      final isBlocked = await userBlockService.isBlocked(currentUserId, targetUserId);
      expect(isBlocked, true);
    });

    test('isBlocked returns false when user is not blocked', () async {
      final isBlocked = await userBlockService.isBlocked(currentUserId, targetUserId);
      expect(isBlocked, false);
    });

    test('unblockUser removes document', () async {
      await userBlockService.blockUser(currentUserId, targetUserId);
      await userBlockService.unblockUser(currentUserId, targetUserId);

      final isBlocked = await userBlockService.isBlocked(currentUserId, targetUserId);
      expect(isBlocked, false);
    });

    test('getBlockedUserIds returns list of blocked ids', () async {
      await userBlockService.blockUser(currentUserId, 'user2');
      await userBlockService.blockUser(currentUserId, 'user3');

      final blockedIds = await userBlockService.getBlockedUserIds(currentUserId);
      expect(blockedIds, containsAll(['user2', 'user3']));
      expect(blockedIds.length, 2);
    });
  });
}
