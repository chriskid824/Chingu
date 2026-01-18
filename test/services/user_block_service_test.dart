import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/user_block_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService Test', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreService firestoreService;
    late UserBlockService userBlockService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      firestoreService = FirestoreService(); // We can't easily mock this without dependency injection or Mockito, but we are testing UserBlockService logic which uses Firestore directly mostly
      // To properly unit test without mocking FirestoreService in UserBlockService, we might rely on the fact that UserBlockService uses _firestore directly for updates.
      // However, UserBlockService constructor takes FirestoreService.
      // Let's pass null for firestoreService if it's not strictly needed for the methods we are testing, or we need to mock it if it is.
      // Looking at UserBlockService implementation:
      // blockUser -> uses _firestore
      // unblockUser -> uses _firestore
      // getBlockedUserIds -> uses _firestore
      // isUserBlocked -> uses getBlockedUserIds
      // So we don't strictly need a real FirestoreService for these tests if we pass the fakeFirestore instance.

      userBlockService = UserBlockService(
        firestore: fakeFirestore,
        firestoreService: firestoreService, // Passing real one, but it won't be used for the methods under test heavily or we can ignore its internal calls if any
      );
    });

    test('blockUser should add user to blockedUsers list', () async {
      const currentUserId = 'user1';
      const targetUserId = 'user2';

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      await userBlockService.blockUser(currentUserId, targetUserId);

      final userDoc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(userDoc.data()!['blockedUsers']);

      expect(blockedUsers, contains(targetUserId));
    });

    test('blockUser should throw exception if blocking self', () async {
      const currentUserId = 'user1';

      expect(
        () => userBlockService.blockUser(currentUserId, currentUserId),
        throwsException,
      );
    });

    test('unblockUser should remove user from blockedUsers list', () async {
      const currentUserId = 'user1';
      const targetUserId = 'user2';

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [targetUserId],
      });

      await userBlockService.unblockUser(currentUserId, targetUserId);

      final userDoc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(userDoc.data()!['blockedUsers']);

      expect(blockedUsers, isNot(contains(targetUserId)));
    });

    test('getBlockedUserIds should return list of blocked users', () async {
      const currentUserId = 'user1';
      final blockedList = ['user2', 'user3'];

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': blockedList,
      });

      final result = await userBlockService.getBlockedUserIds(currentUserId);
      expect(result, equals(blockedList));
    });

    test('isUserBlocked should return true if user is blocked', () async {
      const currentUserId = 'user1';
      const targetUserId = 'user2';

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [targetUserId],
      });

      final isBlocked = await userBlockService.isUserBlocked(currentUserId, targetUserId);
      expect(isBlocked, isTrue);
    });

    test('isUserBlocked should return false if user is not blocked', () async {
      const currentUserId = 'user1';
      const targetUserId = 'user2';

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      final isBlocked = await userBlockService.isUserBlocked(currentUserId, targetUserId);
      expect(isBlocked, isFalse);
    });
  });
}
