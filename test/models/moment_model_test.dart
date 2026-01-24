import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    // Round to microseconds to match Timestamp precision loss if any,
    // but Timestamp stores nanoseconds, while DateTime in Dart is microseconds.
    // However, when converting back and forth, precision might change.
    // Let's just use a fixed time.

    test('supports value comparisons', () {
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
      expect(moment1, moment2);
    });

    test('toMap returns correct map', () {
      final date = DateTime(2023, 1, 1, 12, 0, 0);
      final moment = MomentModel(
        id: '1',
        userId: 'user1',
        userName: 'User 1',
        userAvatar: 'avatar',
        content: 'content',
        imageUrl: 'image',
        createdAt: date,
        likeCount: 5,
        commentCount: 2,
      );

      final map = moment.toMap();

      expect(map['id'], '1');
      expect(map['userId'], 'user1');
      expect(map['userName'], 'User 1');
      expect(map['userAvatar'], 'avatar');
      expect(map['content'], 'content');
      expect(map['imageUrl'], 'image');
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), date);
      expect(map['likeCount'], 5);
      expect(map['commentCount'], 2);
    });

    test('fromMap returns correct model', () {
      final date = DateTime(2023, 1, 1, 12, 0, 0);
      final map = {
        'id': '1',
        'userId': 'user1',
        'userName': 'User 1',
        'userAvatar': 'avatar',
        'content': 'content',
        'imageUrl': 'image',
        'createdAt': Timestamp.fromDate(date),
        'likeCount': 5,
        'commentCount': 2,
        'isLiked': true,
      };

      final moment = MomentModel.fromMap(map);

      expect(moment.id, '1');
      expect(moment.userId, 'user1');
      expect(moment.userName, 'User 1');
      expect(moment.userAvatar, 'avatar');
      expect(moment.content, 'content');
      expect(moment.imageUrl, 'image');
      expect(moment.createdAt, date);
      expect(moment.likeCount, 5);
      expect(moment.commentCount, 2);
      expect(moment.isLiked, true);
    });

    test('fromMap handles String timestamp (legacy/fallback)', () {
      final date = DateTime(2023, 1, 1, 12, 0, 0);
      final map = {
        'id': '1',
        'userId': 'user1',
        'userName': 'User 1',
        'content': 'content',
        'createdAt': date.toIso8601String(),
      };

      final moment = MomentModel.fromMap(map);

      expect(moment.createdAt, date);
    });
  });
}
