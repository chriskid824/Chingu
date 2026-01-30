import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    final moment = MomentModel(
      id: '123',
      userId: 'user1',
      userName: 'User 1',
      userAvatar: 'http://avatar.com',
      content: 'Hello World',
      imageUrl: 'http://image.com',
      createdAt: now,
      likeCount: 5,
      commentCount: 2,
      isLiked: true,
    );

    test('supports value equality', () {
      expect(moment, equals(moment.copyWith()));
    });

    test('fromMap creates valid instance', () {
      final map = {
        'userId': 'user1',
        'userName': 'User 1',
        'userAvatar': 'http://avatar.com',
        'content': 'Hello World',
        'imageUrl': 'http://image.com',
        'createdAt': timestamp,
        'likeCount': 5,
        'commentCount': 2,
      };

      final result = MomentModel.fromMap(map, '123', isLiked: true);

      // Timestamp precision might differ slightly, so we compare milliseconds
      expect(result.id, '123');
      expect(result.userId, 'user1');
      expect(result.content, 'Hello World');
      expect(result.isLiked, true);
      expect(result.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('toMap creates valid map', () {
      final map = moment.toMap();

      expect(map['userId'], 'user1');
      expect(map['content'], 'Hello World');
      expect(map['createdAt'], isA<Timestamp>());
      // isLiked should NOT be in map
      expect(map.containsKey('isLiked'), false);
    });
  });
}
