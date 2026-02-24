import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/report_block_service.dart';
import 'package:chingu/models/report_model.dart';

void main() {
  group('ReportBlockService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late ReportBlockService service;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      service = ReportBlockService(firestore: fakeFirestore);
    });

    // ==================== 封鎖功能測試 ====================

    group('Block User', () {
      test('should block a user', () async {
        const userId = 'user1';
        const blockedUserId = 'user2';

        await service.blockUser(userId, blockedUserId);

        final blockedIds = await service.getBlockedUserIds(userId);
        expect(blockedIds, contains(blockedUserId));
      });

      test('should block multiple users', () async {
        const userId = 'user1';

        await service.blockUser(userId, 'blocked1');
        await service.blockUser(userId, 'blocked2');
        await service.blockUser(userId, 'blocked3');

        final blockedIds = await service.getBlockedUserIds(userId);
        expect(blockedIds.length, equals(3));
        expect(blockedIds, containsAll(['blocked1', 'blocked2', 'blocked3']));
      });

      test('should not duplicate blocked user', () async {
        const userId = 'user1';
        const blockedUserId = 'user2';

        await service.blockUser(userId, blockedUserId);
        await service.blockUser(userId, blockedUserId);

        final blockedIds = await service.getBlockedUserIds(userId);
        expect(blockedIds.where((id) => id == blockedUserId).length, equals(1));
      });
    });

    group('Unblock User', () {
      test('should unblock a user', () async {
        const userId = 'user1';
        const blockedUserId = 'user2';

        // 先封鎖
        await service.blockUser(userId, blockedUserId);
        var blockedIds = await service.getBlockedUserIds(userId);
        expect(blockedIds, contains(blockedUserId));

        // 解除封鎖
        await service.unblockUser(userId, blockedUserId);
        blockedIds = await service.getBlockedUserIds(userId);
        expect(blockedIds, isNot(contains(blockedUserId)));
      });
    });

    group('Is Blocked', () {
      test('should return true if user is blocked', () async {
        const userId = 'user1';
        const blockedUserId = 'user2';

        await service.blockUser(userId, blockedUserId);

        final isBlocked = await service.isBlocked(userId, blockedUserId);
        expect(isBlocked, isTrue);
      });

      test('should return false if user is not blocked', () async {
        const userId = 'user1';
        const targetUserId = 'user2';

        final isBlocked = await service.isBlocked(userId, targetUserId);
        expect(isBlocked, isFalse);
      });
    });

    group('Is Either Blocked', () {
      test('should return true if first user blocked second', () async {
        await service.blockUser('user1', 'user2');

        final isEitherBlocked = await service.isEitherBlocked('user1', 'user2');
        expect(isEitherBlocked, isTrue);
      });

      test('should return true if second user blocked first', () async {
        await service.blockUser('user2', 'user1');

        final isEitherBlocked = await service.isEitherBlocked('user1', 'user2');
        expect(isEitherBlocked, isTrue);
      });

      test('should return false if neither blocked', () async {
        final isEitherBlocked = await service.isEitherBlocked('user1', 'user2');
        expect(isEitherBlocked, isFalse);
      });
    });

    // ==================== 舉報功能測試 ====================

    group('Report User', () {
      test('should create a report', () async {
        await service.reportUser(
          reporterId: 'reporter1',
          reportedUserId: 'reported1',
          reason: ReportReason.harassment,
          description: 'Test report',
        );

        final snapshot = await fakeFirestore.collection('reports').get();
        expect(snapshot.docs.length, equals(1));
        
        final report = snapshot.docs.first.data();
        expect(report['reporterId'], equals('reporter1'));
        expect(report['reportedUserId'], equals('reported1'));
        expect(report['reason'], equals('harassment'));
        expect(report['description'], equals('Test report'));
        expect(report['status'], equals('pending'));
      });

      test('should prevent duplicate pending reports', () async {
        await service.reportUser(
          reporterId: 'reporter1',
          reportedUserId: 'reported1',
          reason: ReportReason.harassment,
        );

        // 第二次舉報應該拋出異常
        expect(
          () => service.reportUser(
            reporterId: 'reporter1',
            reportedUserId: 'reported1',
            reason: ReportReason.spam,
          ),
          throwsException,
        );
      });
    });

    group('Get User Reports', () {
      test('should get user reports', () async {
        await service.reportUser(
          reporterId: 'reporter1',
          reportedUserId: 'reported1',
          reason: ReportReason.harassment,
        );

        await service.reportUser(
          reporterId: 'reporter1',
          reportedUserId: 'reported2',
          reason: ReportReason.fake,
        );

        final reports = await service.getUserReports('reporter1');
        expect(reports.length, equals(2));
      });
    });

    // ==================== 組合操作測試 ====================

    group('Block And Report', () {
      test('should block and report user', () async {
        await service.blockAndReport(
          reporterId: 'user1',
          reportedUserId: 'user2',
          reason: ReportReason.harassment,
          description: 'Blocked and reported',
        );

        // 驗證封鎖
        final isBlocked = await service.isBlocked('user1', 'user2');
        expect(isBlocked, isTrue);

        // 驗證舉報
        final snapshot = await fakeFirestore.collection('reports').get();
        expect(snapshot.docs.length, equals(1));
      });
    });
  });
}
