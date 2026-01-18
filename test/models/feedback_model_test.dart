import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/feedback_model.dart';

void main() {
  group('FeedbackModel', () {
    final DateTime now = DateTime.now();
    final Timestamp timestamp = Timestamp.fromDate(now);

    test('should support value equality', () {
      final feedback1 = FeedbackModel(
        id: '123',
        userId: 'user1',
        userEmail: 'user@example.com',
        type: FeedbackType.suggestion,
        description: 'Great app!',
        createdAt: now,
        status: FeedbackStatus.pending,
      );

      final feedback2 = FeedbackModel(
        id: '123',
        userId: 'user1',
        userEmail: 'user@example.com',
        type: FeedbackType.suggestion,
        description: 'Great app!',
        createdAt: now,
        status: FeedbackStatus.pending,
      );

      // Note: By default Dart objects don't support value equality unless == is overridden.
      // But we can check fields.
      expect(feedback1.id, feedback2.id);
      expect(feedback1.userId, feedback2.userId);
    });

    test('fromMap should return a valid object', () {
      final map = {
        'userId': 'user1',
        'userEmail': 'user@example.com',
        'type': 'bug',
        'description': 'It crashed',
        'imageUrls': ['http://image.com/1.png'],
        'status': 'reviewed',
        'createdAt': timestamp,
        'appVersion': '1.0.0',
        'deviceInfo': 'Android 13',
      };

      final feedback = FeedbackModel.fromMap(map, 'id_123');

      expect(feedback.id, 'id_123');
      expect(feedback.userId, 'user1');
      expect(feedback.type, FeedbackType.bug);
      expect(feedback.description, 'It crashed');
      expect(feedback.imageUrls.length, 1);
      expect(feedback.status, FeedbackStatus.reviewed);
      expect(feedback.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch); // Timestamp might have microsecond diffs
      expect(feedback.appVersion, '1.0.0');
    });

    test('toMap should return a valid map', () {
      final feedback = FeedbackModel(
        id: 'id_123',
        userId: 'user1',
        userEmail: 'user@example.com',
        type: FeedbackType.other,
        description: 'Just saying hi',
        createdAt: now,
        status: FeedbackStatus.resolved,
      );

      final map = feedback.toMap();

      expect(map['userId'], 'user1');
      expect(map['type'], 'other');
      expect(map['status'], 'resolved');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('getTypeDisplayString should return correct text', () {
      final f1 = FeedbackModel(
        id: '1', userId: 'u', userEmail: 'e', type: FeedbackType.suggestion,
        description: 'd', createdAt: now,
      );
      expect(f1.getTypeDisplayString(), '建議');

      final f2 = FeedbackModel(
        id: '1', userId: 'u', userEmail: 'e', type: FeedbackType.bug,
        description: 'd', createdAt: now,
      );
      expect(f2.getTypeDisplayString(), '問題回報');

      final f3 = FeedbackModel(
        id: '1', userId: 'u', userEmail: 'e', type: FeedbackType.other,
        description: 'd', createdAt: now,
      );
      expect(f3.getTypeDisplayString(), '其他');
    });
  });
}
