import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/models/report_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('ReportModel', () {
    test('toMap returns correct map', () {
      final date = DateTime.now();
      final report = ReportModel(
        id: 'test_id',
        reporterId: 'reporter_1',
        reportedUserId: 'reported_1',
        reason: 'Spam',
        description: 'Test description',
        createdAt: date,
        status: 'pending',
        type: 'user_report',
      );

      final map = report.toMap();

      expect(map['reporterId'], 'reporter_1');
      expect(map['reportedUserId'], 'reported_1');
      expect(map['reason'], 'Spam');
      expect(map['description'], 'Test description');
      expect(map['status'], 'pending');
      expect(map['type'], 'user_report');
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap creates correct model', () {
      final date = DateTime.now();
      final map = {
        'reporterId': 'reporter_1',
        'reportedUserId': 'reported_1',
        'reason': 'Spam',
        'description': 'Test description',
        'createdAt': Timestamp.fromDate(date),
        'status': 'pending',
        'type': 'user_report',
      };

      final report = ReportModel.fromMap(map, 'test_id');

      expect(report.id, 'test_id');
      expect(report.reporterId, 'reporter_1');
      expect(report.reportedUserId, 'reported_1');
      expect(report.reason, 'Spam');
      expect(report.description, 'Test description');
      expect(report.status, 'pending');
      expect(report.type, 'user_report');
      // Allow small difference due to precision
      expect(
          report.createdAt.millisecondsSinceEpoch,
          closeTo(date.millisecondsSinceEpoch, 1000),
      );
    });
  });
}
