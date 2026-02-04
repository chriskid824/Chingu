import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    // Round to microseconds to match Firestore precision usually,
    // but here we just need equality in toMap/fromMap logic.
    // Timestamp loses some precision compared to Dart DateTime.

    final moment = MomentModel(
      id: 'test_id',
      userId: 'user_1',
      userName: 'Test User',
      userAvatar: 'http://avatar.url',
      content: 'Test content',
      imageUrl: 'http://image.url',
      createdAt: now,
      likeCount: 5,
      commentCount: 2,
      isLiked: true,
    );

    test('props should contain all fields', () {
      expect(moment.props, [
        moment.id,
        moment.userId,
        moment.userName,
        moment.userAvatar,
        moment.content,
        moment.imageUrl,
        moment.createdAt,
        moment.likeCount,
        moment.commentCount,
        moment.isLiked,
      ]);
    });

    test('toMap should return correct map', () {
      final map = moment.toMap();
      expect(map['userId'], 'user_1');
      expect(map['userName'], 'Test User');
      expect(map['userAvatar'], 'http://avatar.url');
      expect(map['content'], 'Test content');
      expect(map['imageUrl'], 'http://image.url');
      expect(map['likeCount'], 5);
      expect(map['commentCount'], 2);
      expect(map['isLiked'], true);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap should return correct model', () {
      final map = {
        'userId': 'user_1',
        'userName': 'Test User',
        'userAvatar': 'http://avatar.url',
        'content': 'Test content',
        'imageUrl': 'http://image.url',
        'createdAt': Timestamp.fromDate(now),
        'likeCount': 5,
        'commentCount': 2,
        'isLiked': true,
      };

      final newMoment = MomentModel.fromMap(map, 'test_id');
      expect(newMoment.id, 'test_id');
      expect(newMoment.userId, 'user_1');
      expect(newMoment.content, 'Test content');
      // DateTime equality might fail due to precision, so check usually requires close match or same source
      // Here we used Timestamp.fromDate(now) so it should be close.
      // Actually, since we construct from Timestamp, we should compare the DateTimes.
      expect(newMoment.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });
  });
}
