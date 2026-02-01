import 'package:chingu/models/comment_model.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MomentService momentService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    momentService = MomentService(firestore: fakeFirestore);
  });

  group('MomentService', () {
    test('likeMoment should increment likeCount and add user to likes', () async {
      const momentId = 'moment1';
      const userId = 'user1';

      // Setup initial moment
      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 0,
      });

      await momentService.likeMoment(momentId, userId);

      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.get('likeCount'), 1);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, true);
      expect(likeDoc.data()!['userId'], userId);
    });

    test('likeMoment should not double count if already liked', () async {
      const momentId = 'moment1';
      const userId = 'user1';

      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 1,
      });
      await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .set({'userId': userId});

      await momentService.likeMoment(momentId, userId);

      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.get('likeCount'), 1, reason: 'Like count should remain 1');
    });

    test('unlikeMoment should decrement likeCount and remove user from likes', () async {
      const momentId = 'moment1';
      const userId = 'user1';

      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 1,
      });
      await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .set({'userId': userId});

      await momentService.unlikeMoment(momentId, userId);

      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.get('likeCount'), 0);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, false);
    });

    test('addComment should increment commentCount and add comment doc', () async {
      const momentId = 'moment1';

      await fakeFirestore.collection('moments').doc(momentId).set({
        'commentCount': 0,
      });

      final comment = CommentModel(
        id: '', // Empty ID to trigger generation
        momentId: momentId,
        userId: 'user1',
        userName: 'User 1',
        content: 'Hello World',
        createdAt: DateTime.now(),
      );

      await momentService.addComment(momentId, comment);

      final momentDoc = await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc.get('commentCount'), 1);

      final commentsSnapshot = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('comments')
          .get();

      expect(commentsSnapshot.docs.length, 1);
      final commentData = commentsSnapshot.docs.first.data();
      expect(commentData['content'], 'Hello World');
      expect(commentData['id'], isNotEmpty);
      expect(commentData['id'], commentsSnapshot.docs.first.id);
    });
  });
}
