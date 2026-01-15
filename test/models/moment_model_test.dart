import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    test('supports value equality', () {
      final moment1 = MomentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        content: 'content',
        createdAt: DateTime(2023),
      );
      final moment2 = MomentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        content: 'content',
        createdAt: DateTime(2023),
      );
      expect(moment1, equals(moment2));
    });

    test('toMap and fromMap work correctly', () {
      final date = DateTime.now();
      // Truncate to milliseconds to avoid precision issues with Timestamp
      final dateTruncated = DateTime.fromMillisecondsSinceEpoch(date.millisecondsSinceEpoch);

      final moment = MomentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        content: 'content',
        createdAt: dateTruncated,
        likeCount: 5,
        commentCount: 2,
      );

      final map = moment.toMap();

      // Manually handle Timestamp for test simulation
      map['createdAt'] = Timestamp.fromDate(dateTruncated);

      final fromMap = MomentModel.fromMap(map, '1');

      expect(fromMap, equals(moment));
    });
  });

  group('CommentModel', () {
    test('supports value equality', () {
      final comment1 = CommentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        content: 'content',
        createdAt: DateTime(2023),
      );
      final comment2 = CommentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        content: 'content',
        createdAt: DateTime(2023),
      );
      expect(comment1, equals(comment2));
    });
  });
}
