import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ReportModel', () {
    test('should create ReportModel from map', () {
      final date = DateTime.fromMillisecondsSinceEpoch(1600000000000); // Fixed time
      final map = {
        'reporterId': 'user1',
        'reportedUserId': 'user2',
        'reason': 'spam',
        'description': 'spam description',
        'createdAt': Timestamp.fromDate(date),
        'status': 'pending',
        'type': 'user_report',
      };

      final model = ReportModel.fromMap(map, 'report1');

      expect(model.id, 'report1');
      expect(model.reporterId, 'user1');
      expect(model.reportedUserId, 'user2');
      expect(model.reason, 'spam');
      expect(model.description, 'spam description');
      expect(model.createdAt, date);
      expect(model.status, 'pending');
      expect(model.type, 'user_report');
    });

    test('should convert ReportModel to map', () {
      final date = DateTime.fromMillisecondsSinceEpoch(1600000000000);
      final model = ReportModel(
        id: 'report1',
        reporterId: 'user1',
        reportedUserId: 'user2',
        reason: 'spam',
        description: 'spam description',
        createdAt: date,
        status: 'pending',
        type: 'user_report',
      );

      final map = model.toMap();

      expect(map['reporterId'], 'user1');
      expect(map['reportedUserId'], 'user2');
      expect(map['reason'], 'spam');
      expect(map['description'], 'spam description');
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), date);
      expect(map['status'], 'pending');
      expect(map['type'], 'user_report');
    });

    test('copyWith should update fields correctly', () {
      final model = ReportModel(
        id: '1',
        reporterId: 'user1',
        reportedUserId: 'user2',
        reason: 'spam',
        description: 'desc',
        createdAt: DateTime.now(),
      );

      final updated = model.copyWith(status: 'resolved');
      expect(updated.status, 'resolved');
      expect(updated.reason, 'spam');
    });
  });
}
