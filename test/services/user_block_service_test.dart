import 'package:chingu/services/user_block_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late UserBlockService userBlockService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    userBlockService = UserBlockService(firestore: fakeFirestore);
  });

  group('UserBlockService', () {
    const currentUserId = 'user1';
    const targetUserId = 'user2';

    test('blockUser should add targetUserId to blockedUserIds', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(currentUserId).set({});

      // Act
      await userBlockService.blockUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedList = List<String>.from(doc['blockedUserIds']);
      expect(blockedList, contains(targetUserId));
    });

    test('unblockUser should remove targetUserId from blockedUserIds', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'blockedUserIds': [targetUserId, 'user3'],
      });

      // Act
      await userBlockService.unblockUser(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
      );

      // Assert
      final doc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedList = List<String>.from(doc['blockedUserIds']);
      expect(blockedList, isNot(contains(targetUserId)));
      expect(blockedList, contains('user3'));
    });

    test('getBlockedUsers should return the list of blocked user IDs', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'blockedUserIds': [targetUserId, 'user3'],
      });

      // Act
      final result = await userBlockService.getBlockedUsers(currentUserId);

      // Assert
      expect(result, containsAll([targetUserId, 'user3']));
    });

    test('getBlockedUsers should return empty list if no user or no field', () async {
      // Act
      final result = await userBlockService.getBlockedUsers('non_existent');

      // Assert
      expect(result, isEmpty);
    });
  });
}
