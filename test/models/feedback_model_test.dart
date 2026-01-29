import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/feedback_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('FeedbackModel', () {
    test('toMap and fromMap work correctly', () {
      final now = DateTime.now();
      // Round to milliseconds to match Timestamp precision
      final nowRounded = DateTime.fromMillisecondsSinceEpoch(now.millisecondsSinceEpoch);

      final feedback = FeedbackModel(
        id: 'test_id',
        userId: 'user_123',
        userEmail: 'test@example.com',
        type: 'suggestion',
        content: 'Great app!',
        createdAt: nowRounded,
        status: 'new',
        appVersion: '1.0.0',
        platform: 'android',
      );

      final map = feedback.toMap();

      // Verify map structure
      expect(map['userId'], 'user_123');
      expect(map['content'], 'Great app!');
      expect(map['createdAt'], isA<Timestamp>());

      // Simulate Firestore Timestamp behavior (though toMap already does it)
      // We pass the map back to fromMap
      final fromMap = FeedbackModel.fromMap(map, 'test_id');

      expect(fromMap.id, 'test_id');
      expect(fromMap.userId, 'user_123');
      expect(fromMap.userEmail, 'test@example.com');
      expect(fromMap.type, 'suggestion');
      expect(fromMap.content, 'Great app!');
      expect(fromMap.createdAt, nowRounded);
      expect(fromMap.status, 'new');
      expect(fromMap.appVersion, '1.0.0');
      expect(fromMap.platform, 'android');
    });
  });
}
