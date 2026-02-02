import 'package:chingu/models/comment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommentModel', () {
    test('supports value equality', () {
      final now = DateTime.now();
      final comment1 = CommentModel(
        id: '1',
        momentId: 'm1',
        userId: 'u1',
        userName: 'User 1',
        content: 'Content',
        createdAt: now,
      );
      final comment2 = CommentModel(
        id: '1',
        momentId: 'm1',
        userId: 'u1',
        userName: 'User 1',
        content: 'Content',
        createdAt: now,
      );
      expect(comment1, equals(comment2));
    });

    test('fromMap creates correct instance', () {
      final now = DateTime.now();
      // Timestamp in Firestore is usually Timestamp object, but here we can mock map behavior
      // or if fromMap handles Timestamp

      final map = {
        'momentId': 'm1',
        'userId': 'u1',
        'userName': 'User 1',
        'content': 'Content',
        'createdAt': Timestamp.fromDate(now),
      };

      final comment = CommentModel.fromMap(map, '1');
      expect(comment.id, '1');
      expect(comment.momentId, 'm1');
      expect(comment.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('toMap creates correct map', () {
      final now = DateTime.now();
      final comment = CommentModel(
        id: '1',
        momentId: 'm1',
        userId: 'u1',
        userName: 'User 1',
        content: 'Content',
        createdAt: now,
      );

      final map = comment.toMap();
      expect(map['momentId'], 'm1');
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
