import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    const userId = 'user1';
    const targetId = 'user2';

    test('blockUser adds targetId to blockedUsers array', () async {
      // Setup initial user
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      await service.blockUser(userId, targetId);

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      final blockedUsers = List<String>.from(doc['blockedUsers']);

      expect(blockedUsers, contains(targetId));
    });

    test('blockUser throws exception when blocking self', () async {
      expect(
        () => service.blockUser(userId, userId),
        throwsException,
      );
    });

    test('unblockUser removes targetId from blockedUsers array', () async {
      // Setup user with blocked target
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'User 1',
        'blockedUsers': [targetId],
      });

      await service.unblockUser(userId, targetId);

      final doc = await fakeFirestore.collection('users').doc(userId).get();
      final blockedUsers = List<String>.from(doc['blockedUsers']);

      expect(blockedUsers, isNot(contains(targetId)));
    });

    test('isBlocked returns true if user is blocked', () async {
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'User 1',
        'blockedUsers': [targetId],
      });

      final result = await service.isBlocked(userId, targetId);
      expect(result, isTrue);
    });

    test('isBlocked returns false if user is not blocked', () async {
      await fakeFirestore.collection('users').doc(userId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      final result = await service.isBlocked(userId, targetId);
      expect(result, isFalse);
    });
  });
}
