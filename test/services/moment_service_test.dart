import 'package:chingu/services/moment_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MomentService momentService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    momentService = MomentService(firestore: fakeFirestore);
  });

  group('MomentService', () {
    const momentId = 'moment_123';
    const userId = 'user_123';

    test('likeMoment should increment likeCount and add like doc', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 0,
      });

      // Act
      await momentService.likeMoment(momentId, userId);

      // Assert
      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.data()!['likeCount'], 1);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, true);
    });

    test('unlikeMoment should decrement likeCount and remove like doc', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 1,
      });
      await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .set({'likedAt': DateTime.now()});

      // Act
      await momentService.unlikeMoment(momentId, userId);

      // Assert
      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.data()!['likeCount'], 0);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, false);
    });

    test('addComment should increment commentCount and add comment doc', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'commentCount': 0,
      });

      // Act
      await momentService.addComment(momentId, userId, 'Test User', null, 'Hello World');

      // Assert
      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.data()!['commentCount'], 1);

      final commentsSnapshot = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('comments')
          .get();
      expect(commentsSnapshot.docs.length, 1);
      expect(commentsSnapshot.docs.first.data()['content'], 'Hello World');
    });
  });
}
