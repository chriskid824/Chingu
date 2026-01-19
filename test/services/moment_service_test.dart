import 'package:chingu/models/comment_model.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MomentService momentService;
  late FakeFirebaseFirestore fakeFirestore;

  const momentId = 'moment_1';
  const userId = 'user_1';

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    momentService = MomentService(firestore: fakeFirestore);
  });

  group('MomentService', () {
    test('toggleLike should add like and increment count when not liked',
        () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 0,
      });

      // Act
      await momentService.toggleLike(momentId, userId);

      // Assert
      final momentDoc =
          await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc['likeCount'], 1);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, true);
    });

    test('toggleLike should remove like and decrement count when already liked',
        () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'likeCount': 1,
      });
      await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .set({
        'userId': userId,
        'createdAt': DateTime.now(),
      });

      // Act
      await momentService.toggleLike(momentId, userId);

      // Assert
      final momentDoc =
          await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc['likeCount'], 0);

      final likeDoc = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('likes')
          .doc(userId)
          .get();
      expect(likeDoc.exists, false);
    });

    test('addComment should add comment and increment count', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'commentCount': 0,
      });

      // Act
      await momentService.addComment(
          momentId, userId, 'Test comment', 'User 1', null);

      // Assert
      final momentDoc =
          await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc['commentCount'], 1);

      final commentsSnapshot = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('comments')
          .get();
      expect(commentsSnapshot.docs.length, 1);
      final commentData = commentsSnapshot.docs.first.data();
      expect(commentData['content'], 'Test comment');
      expect(commentData['userId'], userId);
      expect(commentData['userName'], 'User 1');
    });

    test('getCommentsStream should emit comments', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'commentCount': 0,
      });
      // Add a comment
      await momentService.addComment(
          momentId, userId, 'First comment', 'User 1', null);

      // Act
      final stream = momentService.getCommentsStream(momentId);

      // Assert
      expect(stream, emits(isA<List<CommentModel>>()));
      final comments = await stream.first;
      expect(comments.length, 1);
      expect(comments.first.content, 'First comment');
    });

    test('deleteComment should remove comment and decrement count', () async {
      // Arrange
      await fakeFirestore.collection('moments').doc(momentId).set({
        'commentCount': 1,
      });
      final commentRef = await fakeFirestore
          .collection('moments')
          .doc(momentId)
          .collection('comments')
          .add({
        'userId': userId,
        'content': 'To be deleted',
      });

      // Act
      await momentService.deleteComment(momentId, commentRef.id);

      // Assert
      final momentDoc =
          await fakeFirestore.collection('moments').doc(momentId).get();
      expect(momentDoc['commentCount'], 0);

      final commentDoc = await commentRef.get();
      expect(commentDoc.exists, false);
    });
  });
}
