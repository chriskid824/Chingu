import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    final moment = MomentModel(
      id: '1',
      userId: 'user1',
      userName: 'User 1',
      content: 'Hello',
      createdAt: now,
      likeCount: 0,
      isLiked: false,
    );

    test('supports value comparisons', () {
      expect(
        moment,
        MomentModel(
          id: '1',
          userId: 'user1',
          userName: 'User 1',
          content: 'Hello',
          createdAt: now,
          likeCount: 0,
          isLiked: false,
        ),
      );
    });

    test('fromMap creates correct instance', () {
      final map = {
        'userId': 'user1',
        'userName': 'User 1',
        'content': 'Hello',
        'createdAt': Timestamp.fromDate(now),
        'likedBy': ['user2'],
      };

      final result = MomentModel.fromMap(map, '1', currentUserId: 'user2');

      expect(result.id, '1');
      expect(result.userId, 'user1');
      expect(result.likeCount, 1);
      expect(result.isLiked, true);
    });

     test('fromMap handles empty likedBy', () {
      final map = {
        'userId': 'user1',
        'userName': 'User 1',
        'content': 'Hello',
        'createdAt': Timestamp.fromDate(now),
      };

      final result = MomentModel.fromMap(map, '1', currentUserId: 'user2');

      expect(result.likeCount, 0);
      expect(result.isLiked, false);
    });
  });
}
