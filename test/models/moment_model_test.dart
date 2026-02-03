import 'package:chingu/models/moment_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MomentModel', () {
    final now = DateTime.now();
    final momentData = {
      'userId': 'user1',
      'userName': 'John Doe',
      'userAvatar': 'avatar.jpg',
      'textContent': 'Hello World',
      'imageUrls': ['img1.jpg', 'img2.jpg'],
      'createdAt': Timestamp.fromDate(now),
      'likeCount': 5,
    };

    test('fromMap creates correct MomentModel', () {
      final moment = MomentModel.fromMap(momentData, 'moment1');

      expect(moment.id, 'moment1');
      expect(moment.userId, 'user1');
      expect(moment.userName, 'John Doe');
      expect(moment.textContent, 'Hello World');
      expect(moment.imageUrls.length, 2);
      // Allow for small time difference or exact match
      expect(moment.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(moment.likeCount, 5);
    });

    test('toMap returns correct map', () {
      final moment = MomentModel(
        id: 'moment1',
        userId: 'user1',
        userName: 'John Doe',
        userAvatar: 'avatar.jpg',
        textContent: 'Hello World',
        imageUrls: ['img1.jpg'],
        createdAt: now,
        likeCount: 5,
      );

      final map = moment.toMap();

      expect(map['userId'], 'user1');
      expect(map['imageUrls'], ['img1.jpg']);
      expect(map['createdAt'], isA<Timestamp>());
    });
  });
}
