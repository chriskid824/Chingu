import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserBlockService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late UserBlockService userBlockService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      userBlockService = UserBlockService(firestore: fakeFirestore);
    });

    test('blockUser adds targetUserId to blockedUsers array', () async {
      final currentUserId = 'user1';
      final targetUserId = 'user2';

      // Setup initial user document
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      // Act
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(doc.data()!['blockedUsers']);
      expect(blockedUsers, contains(targetUserId));
    });

    test('unblockUser removes targetUserId from blockedUsers array', () async {
      final currentUserId = 'user1';
      final targetUserId = 'user2';

      // Setup initial user document with blocked user
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [targetUserId],
      });

      // Act
      await userBlockService.unblockUser(currentUserId, targetUserId);

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(doc.data()!['blockedUsers']);
      expect(blockedUsers, isNot(contains(targetUserId)));
    });

    test('getBlockedUsers returns correct list', () async {
      final currentUserId = 'user1';
      final blockedList = ['user2', 'user3'];

      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': blockedList,
      });

      final result = await userBlockService.getBlockedUsers(currentUserId);
      expect(result, equals(blockedList));
    });

    test('blockUser cannot block self', () async {
      final currentUserId = 'user1';

      expect(
        () => userBlockService.blockUser(currentUserId, currentUserId),
        throwsException,
      );
    });
  });
}
