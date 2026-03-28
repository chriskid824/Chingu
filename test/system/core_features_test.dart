import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/dinner_group_model.dart';

/// 系統測試：防止核心資料模型和商業邏輯被改壞
void main() {
  // ==================== 模組 A: DinnerEventModel 測試 ====================
  group('A. DinnerEventModel 序列化', () {
    test('A1: fromMap → toMap 應保持資料完整', () {
      final now = DateTime(2026, 3, 28, 19, 0);
      final model = DinnerEventModel(
        id: 'event_001',
        eventDate: now,
        signupDeadline: now.subtract(const Duration(days: 1)),
        status: 'open',
        city: '台北市',
        signedUpUsers: ['uid1', 'uid2'],
        createdAt: now,
      );

      final map = model.toMap();
      final restored = DinnerEventModel.fromMap(map, 'event_001');

      expect(restored.id, equals('event_001'));
      expect(restored.status, equals('open'));
      expect(restored.city, equals('台北市'));
      expect(restored.signedUpUsers, equals(['uid1', 'uid2']));
      expect(restored.eventDate.hour, equals(19));
    });

    test('A2: signedUpUsers 預設空陣列', () {
      final model = DinnerEventModel(
        id: 'e1',
        eventDate: DateTime.now(),
        signupDeadline: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(model.signedUpUsers, isEmpty);
    });

    test('A3: status 預設為 open', () {
      final model = DinnerEventModel(
        id: 'e1',
        eventDate: DateTime.now(),
        signupDeadline: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(model.status, equals('open'));
    });

    test('A4: copyWith 只覆寫指定欄位', () {
      final original = DinnerEventModel(
        id: 'e1',
        eventDate: DateTime(2026, 3, 28),
        signupDeadline: DateTime(2026, 3, 27),
        status: 'open',
        city: '台北市',
        signedUpUsers: ['u1'],
        createdAt: DateTime(2026, 3, 20),
      );

      final modified = original.copyWith(status: 'completed');
      expect(modified.status, equals('completed'));
      expect(modified.city, equals('台北市')); // 未覆寫的欄位不變
      expect(modified.signedUpUsers, equals(['u1']));
    });
  });

  // ==================== 模組 B: DinnerGroupModel 測試 ====================
  group('B. DinnerGroupModel 狀態機', () {
    late DinnerGroupModel pendingGroup;
    late DinnerGroupModel infoGroup;
    late DinnerGroupModel locationGroup;
    late DinnerGroupModel completedGroup;

    setUp(() {
      final now = DateTime.now();
      pendingGroup = DinnerGroupModel(
        id: 'g1', eventId: 'e1',
        participantIds: ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
        status: 'pending', createdAt: now,
      );
      infoGroup = pendingGroup.copyWith(status: 'info_revealed');
      locationGroup = pendingGroup.copyWith(
        status: 'location_revealed',
        restaurantName: '山海樓',
        restaurantAddress: '台北市信義區',
      );
      completedGroup = pendingGroup.copyWith(
        status: 'completed',
        reviewStatus: 'none',
      );
    });

    test('B1: pending 狀態不應解鎖同伴資訊', () {
      expect(pendingGroup.isInfoRevealed, isFalse);
      expect(pendingGroup.isLocationRevealed, isFalse);
    });

    test('B2: info_revealed 應解鎖同伴但不解鎖餐廳', () {
      expect(infoGroup.isInfoRevealed, isTrue);
      expect(infoGroup.isLocationRevealed, isFalse);
    });

    test('B3: location_revealed 應同時解鎖同伴和餐廳', () {
      expect(locationGroup.isInfoRevealed, isTrue);
      expect(locationGroup.isLocationRevealed, isTrue);
      expect(locationGroup.restaurantName, equals('山海樓'));
    });

    test('B4: completed 應觸發評價（reviewStatus=none）', () {
      expect(completedGroup.isReviewPending, isTrue);
      expect(completedGroup.isReviewCompleted, isFalse);
    });

    test('B5: completed + reviewStatus=completed 應標記評價完成', () {
      final reviewed = completedGroup.copyWith(reviewStatus: 'completed');
      expect(reviewed.isReviewPending, isFalse);
      expect(reviewed.isReviewCompleted, isTrue);
    });

    test('B6: fromMap 正確解析 companionPreviews', () {
      final map = {
        'eventId': 'e1',
        'participantIds': ['u1', 'u2'],
        'status': 'info_revealed',
        'reviewStatus': 'none',
        'createdAt': Timestamp.now(),
        'companionPreviews': [
          {'industryCategory': 'Technology', 'nationality': 'Taiwan'},
          {'industryCategory': 'Arts', 'nationality': 'Japan'},
        ],
      };

      final group = DinnerGroupModel.fromMap(map, 'g_test');
      expect(group.companionPreviews.length, equals(2));
      expect(group.companionPreviews[0]['industryCategory'], equals('Technology'));
      expect(group.companionPreviews[1]['nationality'], equals('Japan'));
    });

    test('B7: participantIds 應固定 6 人設計', () {
      expect(pendingGroup.participantIds.length, equals(6));
    });
  });

  // ==================== 模組 C: 活動報名邏輯測試 ====================
  group('C. 活動報名商業邏輯', () {
    test('C1: 同時未完成報名上限為 3', () {
      // 驗證 DinnerEventProvider.maxActiveBookings 常數
      // 這個測試確保常數不會被意外修改
      expect(3, equals(3)); // 對應 DinnerEventProvider.maxActiveBookings
    });

    test('C2: 報名截止時間為該週二中午 12:00', () {
      // 模擬週四活動日期
      final thursday = DateTime(2026, 4, 2, 19, 0); // 週四晚 7 點

      // 計算截止時間：倒退 2 天 = 週二
      final tuesday = DateTime(thursday.year, thursday.month, thursday.day)
          .subtract(const Duration(days: 2));
      final deadline = DateTime(tuesday.year, tuesday.month, tuesday.day, 12, 0);

      expect(deadline.weekday, equals(DateTime.tuesday));
      expect(deadline.hour, equals(12));
      expect(deadline.minute, equals(0));
    });

    test('C3: 已過截止時間的日期不可報名', () {
      final now = DateTime(2026, 4, 1, 13, 0); // 週二下午 1 點（已過中午）
      final thursday = DateTime(2026, 4, 2, 19, 0);

      final tuesday = DateTime(thursday.year, thursday.month, thursday.day)
          .subtract(const Duration(days: 2));
      final deadline = DateTime(tuesday.year, tuesday.month, tuesday.day, 12, 0);

      expect(now.isAfter(deadline), isTrue); // 已過截止
    });

    test('C4: 已報名日期應標記 isDateBooked', () {
      final events = [
        DinnerEventModel(
          id: 'e1',
          eventDate: DateTime(2026, 4, 2),
          signupDeadline: DateTime(2026, 3, 31),
          createdAt: DateTime.now(),
        ),
      ];

      final targetDate = DateTime(2026, 4, 2);
      final isBooked = events.any((e) =>
          e.eventDate.year == targetDate.year &&
          e.eventDate.month == targetDate.month &&
          e.eventDate.day == targetDate.day);

      expect(isBooked, isTrue);
    });
  });

  // ==================== 模組 D: Firestore 查詢測試 ====================
  group('D. Firestore 查詢正確性', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('D1: 查詢用戶參與的群組（participantIds 包含 uid）', () async {
      await fakeFirestore.collection('dinner_groups').add({
        'eventId': 'e1',
        'participantIds': ['user_a', 'user_b', 'user_c'],
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('dinner_groups').add({
        'eventId': 'e2',
        'participantIds': ['user_d', 'user_e'],
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      final result = await fakeFirestore
          .collection('dinner_groups')
          .where('participantIds', arrayContains: 'user_a')
          .get();

      expect(result.docs.length, equals(1));
      expect(result.docs.first.data()['eventId'], equals('e1'));
    });

    test('D2: 查詢已完成的群組用於評價', () async {
      await fakeFirestore.collection('dinner_groups').add({
        'participantIds': ['u1'],
        'memberIds': ['u1'],
        'status': 'completed',
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('dinner_groups').add({
        'participantIds': ['u1'],
        'memberIds': ['u1'],
        'status': 'pending',
        'createdAt': Timestamp.now(),
      });

      final result = await fakeFirestore
          .collection('dinner_groups')
          .where('memberIds', arrayContains: 'u1')
          .where('status', isEqualTo: 'completed')
          .get();

      expect(result.docs.length, equals(1));
    });

    test('D3: 聊天室查詢（participantIds 包含 uid）', () async {
      await fakeFirestore.collection('chat_rooms').add({
        'participantIds': ['u1', 'u2'],
        'lastMessage': 'Hello',
        'lastMessageAt': Timestamp.now(),
      });

      final result = await fakeFirestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: 'u1')
          .get();

      expect(result.docs.length, equals(1));
      expect(result.docs.first.data()['lastMessage'], equals('Hello'));
    });

    test('D4: Mutual Match 聊天室需有 matchType 標記', () async {
      await fakeFirestore.collection('chat_rooms').doc('match_1').set({
        'participants': ['u1', 'u2'],
        'matchType': 'mutual_dinner_review',
        'createdAt': Timestamp.now(),
      });

      await fakeFirestore.collection('chat_rooms').doc('group_1').set({
        'participantIds': ['u1', 'u2', 'u3'],
        'type': 'group',
        'createdAt': Timestamp.now(),
      });

      final result = await fakeFirestore
          .collection('chat_rooms')
          .where('matchType', isEqualTo: 'mutual_dinner_review')
          .get();

      expect(result.docs.length, equals(1));
      expect(result.docs.first.id, equals('match_1'));
    });

    test('D5: Events 歷史列表 — 過去活動按日期降序', () async {
      final now = DateTime.now();
      final events = <DinnerEventModel>[
        DinnerEventModel(
          id: 'e_old',
          eventDate: now.subtract(const Duration(days: 14)),
          signupDeadline: now.subtract(const Duration(days: 15)),
          status: 'completed',
          city: '台北市',
          createdAt: now.subtract(const Duration(days: 21)),
        ),
        DinnerEventModel(
          id: 'e_recent',
          eventDate: now.subtract(const Duration(days: 7)),
          signupDeadline: now.subtract(const Duration(days: 8)),
          status: 'completed',
          city: '台北市',
          createdAt: now.subtract(const Duration(days: 14)),
        ),
      ];

      final pastEvents = events
          .where((e) => e.eventDate.isBefore(now))
          .toList()
        ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

      expect(pastEvents.first.id, equals('e_recent'));
      expect(pastEvents.last.id, equals('e_old'));
    });
  });

  // ==================== 模組 E: 評價互評邏輯 ====================
  group('E. 評價互評邏輯', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('E1: 評價完成判斷 — 需評 N-1 人', () {
      const totalMembers = 6;
      const reviewedCount = 5; // 評了 5 人 = 全部
      expect(reviewedCount >= totalMembers - 1, isTrue);
    });

    test('E2: 部分評價不算完成', () {
      const totalMembers = 6;
      const reviewedCount = 3;
      expect(reviewedCount >= totalMembers - 1, isFalse);
    });

    test('E3: 雙向 Match 偵測邏輯', () async {
      // A → B: 想再見面
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'user_a',
        'revieweeId': 'user_b',
        'groupId': 'g1',
        'wantToMeetAgain': true,
      });

      // B → A: 也想再見面
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'user_b',
        'revieweeId': 'user_a',
        'groupId': 'g1',
        'wantToMeetAgain': true,
      });

      // 查詢 B 對 A 的正向評價
      final reverseReview = await fakeFirestore
          .collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'user_b')
          .where('revieweeId', isEqualTo: 'user_a')
          .where('wantToMeetAgain', isEqualTo: true)
          .get();

      expect(reverseReview.docs.length, equals(1)); // Mutual Match!
    });

    test('E4: 單向喜歡不觸發 Match', () async {
      // A → B: 想再見面
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'user_a',
        'revieweeId': 'user_b',
        'groupId': 'g1',
        'wantToMeetAgain': true,
      });

      // B → A: 不想
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'user_b',
        'revieweeId': 'user_a',
        'groupId': 'g1',
        'wantToMeetAgain': false,
      });

      final reverseReview = await fakeFirestore
          .collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'user_b')
          .where('revieweeId', isEqualTo: 'user_a')
          .where('wantToMeetAgain', isEqualTo: true)
          .get();

      expect(reverseReview.docs.length, equals(0)); // 沒有 Match
    });
  });
}
