import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

void main() {
  group('FeedbackModel', () {
    test('toMap should return correct map', () {
      final now = DateTime.now();
      final feedback = FeedbackModel(
        userId: 'user123',
        type: FeedbackType.suggestion,
        content: 'Great app!',
        createdAt: now,
      );

      final map = feedback.toMap();

      expect(map['userId'], 'user123');
      expect(map['type'], 'suggestion');
      expect(map['content'], 'Great app!');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['status'], 'open');
    });

    test('fromMap should return correct FeedbackModel', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user123',
        'type': 'problem',
        'content': 'Bug found',
        'createdAt': Timestamp.fromDate(now),
        'status': 'resolved',
      };

      final feedback = FeedbackModel.fromMap(map, 'id123');

      expect(feedback.id, 'id123');
      expect(feedback.userId, 'user123');
      expect(feedback.type, FeedbackType.problem);
      expect(feedback.content, 'Bug found');
      expect(feedback.status, 'resolved');
      // Precision might slightly differ due to Timestamp conversion, so checking within margin or just components
      expect(feedback.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
    });

    test('fromMap should handle defaults and missing values', () {
      final now = DateTime.now();
      final map = {
        'userId': 'user123',
        'content': 'Something',
        'createdAt': Timestamp.fromDate(now),
      };

      final feedback = FeedbackModel.fromMap(map, 'id456');

      expect(feedback.type, FeedbackType.other); // Default from "orElse" logic in code? No, 'other' is string.
      // Wait, in my code:
      // type: FeedbackType.values.firstWhere(
      //   (e) => e.name == (map['type'] ?? 'other'),
      //   orElse: () => FeedbackType.other,
      // ),
      // If map['type'] is null, it defaults to 'other' string, which matches FeedbackType.other.name ('other').

      expect(feedback.status, 'open');
    });
  });
}
