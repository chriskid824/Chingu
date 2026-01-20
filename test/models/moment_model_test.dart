import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    // Round to microseconds to avoid precision issues during comparison if Timestamp loses precision
    final safeNow = now.copyWith(microsecond: 0);

    final moment = MomentModel(
      id: 'test_id',
      userId: 'user_1',
      userName: 'Test User',
      userAvatar: 'avatar_url',
      content: 'Hello World',
      imageUrl: 'image_url',
      createdAt: safeNow,
      likeCount: 5,
      commentCount: 2,
      isLiked: true,
    );

    test('supports value equality', () {
      expect(
        moment,
        MomentModel(
          id: 'test_id',
          userId: 'user_1',
          userName: 'Test User',
          userAvatar: 'avatar_url',
          content: 'Hello World',
          imageUrl: 'image_url',
          createdAt: safeNow,
          likeCount: 5,
          commentCount: 2,
          isLiked: true,
        ),
      );
    });

    test('toMap returns correct map', () {
      final map = moment.toMap();
      expect(map['userId'], 'user_1');
      expect(map['userName'], 'Test User');
      expect(map['content'], 'Hello World');
      expect(map['likeCount'], 5);
      expect(map['isLiked'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap creates correct model', () {
      final map = {
        'userId': 'user_1',
        'userName': 'Test User',
        'userAvatar': 'avatar_url',
        'content': 'Hello World',
        'imageUrl': 'image_url',
        'createdAt': Timestamp.fromDate(safeNow),
        'likeCount': 5,
        'commentCount': 2,
        'isLiked': true,
      };

      final newMoment = MomentModel.fromMap(map, 'test_id');
      expect(newMoment, moment);
    });
  });
}
