import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    test('fromJson should correctly parse JSON data', () {
      final now = DateTime.now();
      // Remove microseconds for comparison as Firestore Timestamp precision can vary or round trip can lose it
      final nowTruncated = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

      final json = {
        'id': '123',
        'userId': 'user1',
        'userName': 'User One',
        'userAvatar': 'avatar_url',
        'content': 'Hello world',
        'imageUrl': 'image_url',
        'createdAt': Timestamp.fromDate(nowTruncated),
        'likeCount': 10,
        'commentCount': 5,
        'isLiked': true,
      };

      final moment = MomentModel.fromJson(json);

      expect(moment.id, '123');
      expect(moment.userId, 'user1');
      expect(moment.userName, 'User One');
      expect(moment.userAvatar, 'avatar_url');
      expect(moment.content, 'Hello world');
      expect(moment.imageUrl, 'image_url');
      expect(moment.createdAt, nowTruncated);
      expect(moment.likeCount, 10);
      expect(moment.commentCount, 5);
      expect(moment.isLiked, true);
    });

    test('toJson should correctly convert to JSON', () {
      final now = DateTime.now();
      final nowTruncated = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

      final moment = MomentModel(
        id: '123',
        userId: 'user1',
        userName: 'User One',
        userAvatar: 'avatar_url',
        content: 'Hello world',
        imageUrl: 'image_url',
        createdAt: nowTruncated,
        likeCount: 10,
        commentCount: 5,
        isLiked: true,
      );

      final json = moment.toJson();

      expect(json['id'], '123');
      expect(json['userId'], 'user1');
      expect(json['userName'], 'User One');
      expect(json['userAvatar'], 'avatar_url');
      expect(json['content'], 'Hello world');
      expect(json['imageUrl'], 'image_url');
      expect((json['createdAt'] as Timestamp).toDate(), nowTruncated);
      expect(json['likeCount'], 10);
      expect(json['commentCount'], 5);
      expect(json['isLiked'], true);
    });
  });
}
