import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/user_block_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserBlockService userBlockService;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: firestore);
  });

  group('UserBlockService', () {
    const String myUid = 'user_1';
    const String targetUid = 'user_2';

    test('blockUser should create documents in both collections', () async {
      await userBlockService.blockUser(myUid, targetUid);

      final blockDoc = await firestore
          .collection('users')
          .doc(myUid)
          .collection('blocks')
          .doc(targetUid)
          .get();

      expect(blockDoc.exists, isTrue);

      final blockedByDoc = await firestore
          .collection('users')
          .doc(targetUid)
          .collection('blocked_by')
          .doc(myUid)
          .get();

      expect(blockedByDoc.exists, isTrue);
    });

    test('unblockUser should remove documents from both collections', () async {
      // First block
      await userBlockService.blockUser(myUid, targetUid);

      // Then unblock
      await userBlockService.unblockUser(myUid, targetUid);

      final blockDoc = await firestore
          .collection('users')
          .doc(myUid)
          .collection('blocks')
          .doc(targetUid)
          .get();

      expect(blockDoc.exists, isFalse);

      final blockedByDoc = await firestore
          .collection('users')
          .doc(targetUid)
          .collection('blocked_by')
          .doc(myUid)
          .get();

      expect(blockedByDoc.exists, isFalse);
    });

    test('isBlocked should return true if user is blocked', () async {
      await userBlockService.blockUser(myUid, targetUid);

      final result = await userBlockService.isBlocked(myUid, targetUid);
      expect(result, isTrue);
    });

    test('getAllExcludedIds should return union of blocks and blocked_by', () async {
      const String user3 = 'user_3';

      // I block user_2
      await userBlockService.blockUser(myUid, targetUid);

      // user_3 blocks me (manually simulate this)
      await firestore
          .collection('users')
          .doc(myUid)
          .collection('blocked_by')
          .doc(user3)
          .set({'blockedAt': DateTime.now()});

      final excludedIds = await userBlockService.getAllExcludedIds(myUid);

      expect(excludedIds, containsAll([targetUid, user3]));
      expect(excludedIds.length, 2);
    });
  });
}
