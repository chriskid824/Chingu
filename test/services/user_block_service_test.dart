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

    test('blockUser should add targetUserId to blockedUsers list', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [],
      });

      // Act
      await userBlockService.blockUser(currentUserId, targetUserId);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(userDoc.data()!['blockedUsers']);
      expect(blockedUsers, contains(targetUserId));
    });

    test('unblockUser should remove targetUserId from blockedUsers list', () async {
      // Arrange
      await fakeFirestore.collection('users').doc(currentUserId).set({
        'name': 'User 1',
        'blockedUsers': [targetUserId],
      });

      // Act
      await userBlockService.unblockUser(currentUserId, targetUserId);

      // Assert
      final userDoc = await fakeFirestore.collection('users').doc(currentUserId).get();
      final blockedUsers = List<String>.from(userDoc.data()!['blockedUsers']);
      expect(blockedUsers, isNot(contains(targetUserId)));
    });
  });
}
