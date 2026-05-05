import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/feedback_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FeedbackModel', () {
    test('toMap returns correct map', () {
      final now = DateTime.now();
      final feedback = FeedbackModel(
        userId: 'user123',
        category: 'suggestion',
        content: 'Great app!',
        createdAt: now,
        platform: 'android',
      );

      final map = feedback.toMap();

      expect(map['userId'], 'user123');
      expect(map['category'], 'suggestion');
      expect(map['content'], 'Great app!');
      expect(map['status'], 'pending');
      expect(map['platform'], 'android');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap creates correct model', () {
      final now = DateTime.now();
      // Use fromMillisecondsSinceEpoch to ensure precision match with what we'll get back
      final nowTruncated = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

      final map = {
        'userId': 'user123',
        'category': 'bug',
        'content': 'Crash on launch',
        'createdAt': Timestamp.fromDate(nowTruncated),
        'status': 'reviewed',
        'platform': 'ios',
      };

      final feedback = FeedbackModel.fromMap(map, 'feedback_id');

      expect(feedback.id, 'feedback_id');
      expect(feedback.userId, 'user123');
      expect(feedback.category, 'bug');
      expect(feedback.content, 'Crash on launch');
      expect(feedback.status, 'reviewed');
      expect(feedback.platform, 'ios');
      expect(feedback.createdAt.millisecondsSinceEpoch, nowTruncated.millisecondsSinceEpoch);
    });
  });
}
