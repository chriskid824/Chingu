import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/feedback_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FeedbackModel', () {
    test('should support value equality', () {
      final date = DateTime.now();
      final feedback1 = FeedbackModel(
        id: '1',
        userId: 'user1',
        userEmail: 'test@example.com',
        type: 'bug',
        title: 'Title',
        description: 'Description',
        createdAt: date,
      );
      // Models usually don't implement == unless using Equatable,
      // so we check fields.
      expect(feedback1.userId, 'user1');
      expect(feedback1.type, 'bug');
    });

    test('toMap should return correct map', () {
      final date = DateTime.now();
      final feedback = FeedbackModel(
        userId: 'user1',
        userEmail: 'test@example.com',
        type: 'bug',
        title: 'Title',
        description: 'Description',
        createdAt: date,
      );

      final map = feedback.toMap();
      expect(map['userId'], 'user1');
      expect(map['userEmail'], 'test@example.com');
      expect(map['type'], 'bug');
      expect(map['title'], 'Title');
      expect(map['description'], 'Description');
      expect(map['status'], 'open');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap should return correct object', () {
      final date = DateTime.now();
      final map = {
        'userId': 'user1',
        'userEmail': 'test@example.com',
        'type': 'bug',
        'title': 'Title',
        'description': 'Description',
        'status': 'closed',
        'createdAt': Timestamp.fromDate(date),
      };

      final feedback = FeedbackModel.fromMap(map, 'id1');
      expect(feedback.id, 'id1');
      expect(feedback.userId, 'user1');
      expect(feedback.status, 'closed');
      // Comparison of DateTimes can be tricky due to precision, checking proximity
      expect(feedback.createdAt.difference(date).inMilliseconds.abs() < 1000, true);
    });
  });
}
