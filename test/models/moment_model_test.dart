import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('MomentModel', () {
    final timestamp = Timestamp.now();
    final date = timestamp.toDate();

    final momentData = {
      'userId': 'user_123',
      'userName': 'Test User',
      'userAvatar': 'https://example.com/avatar.jpg',
      'content': 'Hello World',
      'imageUrl': 'https://example.com/image.jpg',
      'createdAt': timestamp,
      'likeCount': 10,
      'commentCount': 5,
      'isLiked': true,
    };

    final moment = MomentModel(
      id: 'moment_123',
      userId: 'user_123',
      userName: 'Test User',
      userAvatar: 'https://example.com/avatar.jpg',
      content: 'Hello World',
      imageUrl: 'https://example.com/image.jpg',
      createdAt: date,
      likeCount: 10,
      commentCount: 5,
      isLiked: true,
    );

    test('supports value equality', () {
      expect(
        moment,
        equals(
          MomentModel(
            id: 'moment_123',
            userId: 'user_123',
            userName: 'Test User',
            userAvatar: 'https://example.com/avatar.jpg',
            content: 'Hello World',
            imageUrl: 'https://example.com/image.jpg',
            createdAt: date,
            likeCount: 10,
            commentCount: 5,
            isLiked: true,
          ),
        ),
      );
    });

    test('fromMap creates correct MomentModel', () {
      final result = MomentModel.fromMap(momentData, 'moment_123');
      expect(result, equals(moment));
    });

    test('toMap creates correct map', () {
      final result = moment.toMap();
      expect(result, equals(momentData));
    });

    test('copyWith creates correct MomentModel with updated values', () {
      final updatedMoment = moment.copyWith(
        content: 'New Content',
        likeCount: 11,
      );

      expect(updatedMoment.content, equals('New Content'));
      expect(updatedMoment.likeCount, equals(11));
      expect(updatedMoment.id, equals(moment.id)); // Should remain unchanged
    });
  });
}
