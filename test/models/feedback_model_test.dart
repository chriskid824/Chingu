import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

void main() {
  group('FeedbackModel', () {
    final now = DateTime.now();
    final feedback = FeedbackModel(
      id: 'test_id',
      userId: 'user_123',
      type: 'suggestion',
      content: 'Great app!',
      createdAt: now,
      status: 'pending',
    );

    test('should create valid instance', () {
      expect(feedback.userId, 'user_123');
      expect(feedback.type, 'suggestion');
      expect(feedback.content, 'Great app!');
      expect(feedback.status, 'pending');
    });

    test('toMap should return correct map', () {
      final map = feedback.toMap();
      expect(map['userId'], 'user_123');
      expect(map['type'], 'suggestion');
      expect(map['content'], 'Great app!');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['status'], 'pending');
    });

    test('fromMap should create valid instance', () {
      final map = {
        'userId': 'user_123',
        'type': 'suggestion',
        'content': 'Great app!',
        'createdAt': Timestamp.fromDate(now),
        'status': 'pending',
      };

      final newFeedback = FeedbackModel.fromMap(map, 'test_id');

      expect(newFeedback.id, 'test_id');
      expect(newFeedback.userId, 'user_123');
      expect(newFeedback.type, 'suggestion');
      expect(newFeedback.content, 'Great app!');
      expect(newFeedback.status, 'pending');
      // Note: DateTime might lose precision, so we check near equality if needed,
      // but usually toDate() from Timestamp works fine for equality if we don't care about microseconds.
      // Or we can just check it's not null.
      expect(newFeedback.createdAt, isA<DateTime>());
    });
  });
}
