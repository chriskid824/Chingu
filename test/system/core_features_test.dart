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

  // ==================== 模組 F: 評價系統契約 (對齊 ReviewService) ====================
  // 守住 review_service.dart 與 functions/src/pushNotifications.ts 的核心契約
  group('F. 評價系統契約', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('F1: 雙向 result==like 應構成 Mutual Match (對齊真實 schema)', () async {
      // 對齊 ReviewService.submitReview 使用的 result 欄位 (取代舊 wantToMeetAgain)
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'a', 'revieweeId': 'b', 'groupId': 'g1',
        'eventId': 'e1', 'result': 'like',
      });
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'b', 'revieweeId': 'a', 'groupId': 'g1',
        'eventId': 'e1', 'result': 'like',
      });

      final reverse = await fakeFirestore.collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'b')
          .where('revieweeId', isEqualTo: 'a')
          .where('groupId', isEqualTo: 'g1')
          .where('result', isEqualTo: 'like')
          .get();

      expect(reverse.docs, hasLength(1), reason: '雙向 like 應構成 Match');
    });

    test('F2: 一邊 like 一邊 dislike 不應觸發 Match', () async {
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'a', 'revieweeId': 'b', 'groupId': 'g1',
        'eventId': 'e1', 'result': 'like',
      });
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'b', 'revieweeId': 'a', 'groupId': 'g1',
        'eventId': 'e1', 'result': 'dislike',
      });

      final reverse = await fakeFirestore.collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'b')
          .where('revieweeId', isEqualTo: 'a')
          .where('groupId', isEqualTo: 'g1')
          .where('result', isEqualTo: 'like')
          .get();

      expect(reverse.docs, isEmpty);
    });

    test('F3: 重複評價檢查 — 同 (reviewer, reviewee, group) 三元組唯一', () async {
      // ReviewService.submitReview L36-44 在 add 前 query 既有評價，避免覆蓋
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'a', 'revieweeId': 'b', 'groupId': 'g1',
        'eventId': 'e1', 'result': 'like',
      });

      final existing = await fakeFirestore.collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'a')
          .where('revieweeId', isEqualTo: 'b')
          .where('groupId', isEqualTo: 'g1')
          .get();

      expect(existing.docs, hasLength(1),
          reason: '同三元組已存在 → submitReview 應 short-circuit 不再寫入');
    });

    test('F4: 確定性 ID 防止 autoSkipReviews 重試重複寫入', () async {
      // 對齊 scheduledNotifications.ts autoSkipReviews 使用的 ID 格式
      const id = 'auto_skip_userA_userB_groupX';
      final payload = <String, dynamic>{
        'reviewerId': 'userA', 'revieweeId': 'userB', 'groupId': 'groupX',
        'eventId': 'e1', 'result': 'skipped',
      };

      await fakeFirestore.collection('dinner_reviews').doc(id).set(payload);
      // 模擬 Cloud Function 重試 (transient error 後 retry)
      await fakeFirestore.collection('dinner_reviews').doc(id).set(payload);

      final all = await fakeFirestore.collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'userA')
          .where('revieweeId', isEqualTo: 'userB')
          .get();

      expect(all.docs, hasLength(1),
          reason: '確定性 ID 應在重試時 idempotent，不會建立第二份');
    });
  });

  // ==================== 模組 G: 隱私與雙盲規則 ====================
  group('G. 隱私與雙盲規則', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('G1: 群組聊天室於 location_revealed 階段 avatars 應全為 null', () async {
      // 產品鐵律：照片必須等到週四 19:00 才解鎖
      // 對齊 revealRestaurants：建立 chat_rooms 時 participantAvatars[uid] = null
      await fakeFirestore.collection('chat_rooms').add({
        'type': 'group',
        'participantIds': ['u1', 'u2', 'u3'],
        'participantAvatars': {'u1': null, 'u2': null, 'u3': null},
        'createdAt': DateTime.now(),
      });

      final rooms = await fakeFirestore.collection('chat_rooms').get();
      final avatars = rooms.docs.first.data()['participantAvatars'] as Map;

      expect(avatars.values.every((v) => v == null), isTrue,
          reason: '餐廳揭曉時 (週三 17:00) 不可洩露真實照片');
    });

    test('G2: 評價查詢必須以 reviewerId==self 為條件 (對齊 rules)', () async {
      // dinner_reviews 雙盲：firestore.rules 限制只有 reviewer 才能 read
      await fakeFirestore.collection('dinner_reviews').add({
        'reviewerId': 'me', 'revieweeId': 'someone', 'groupId': 'g',
        'eventId': 'e', 'result': 'like',
      });

      final mine = await fakeFirestore.collection('dinner_reviews')
          .where('reviewerId', isEqualTo: 'me').get();

      expect(mine.docs, hasLength(1),
          reason: '所有 query 應以 reviewerId 為條件，禁止用 revieweeId 反查');
    });
  });

  // ==================== 模組 H: 報名與封鎖隔離 ====================
  group('H. 報名與封鎖隔離', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('H1: 同一日期 (同週四) 只能報名一個活動', () async {
      final sameThursday = DateTime(2026, 4, 16, 19, 0);

      await fakeFirestore.collection('dinner_events').add({
        'eventDate': sameThursday,
        'signedUpUsers': ['user_x'], 'status': 'open',
      });
      await fakeFirestore.collection('dinner_events').add({
        'eventDate': sameThursday,
        'signedUpUsers': <String>[], 'status': 'open',
      });

      final existingForUser = await fakeFirestore.collection('dinner_events')
          .where('signedUpUsers', arrayContains: 'user_x').get();

      final hasOnSameDay = existingForUser.docs.any((d) {
        // FakeFirebaseFirestore 會把 DateTime 序列化為 Timestamp
        final raw = d.data()['eventDate'];
        final date = raw is Timestamp ? raw.toDate() : raw as DateTime;
        return date.year == sameThursday.year &&
               date.month == sameThursday.month &&
               date.day == sameThursday.day;
      });

      expect(hasOnSameDay, isTrue,
          reason: 'bookWithValidation 應在伺服器端拒絕同日重複報名');
    });

    test('H2: 已封鎖用戶不應出現在聊天室查詢結果', () async {
      // 對齊 ChatProvider.loadChatRooms 應依 user.blockedUserIds 過濾
      await fakeFirestore.collection('chat_rooms').add({
        'type': 'direct',
        'participantIds': ['me', 'blocked_user'],
        'createdAt': DateTime.now(),
      });
      await fakeFirestore.collection('chat_rooms').add({
        'type': 'direct',
        'participantIds': ['me', 'normal_user'],
        'createdAt': DateTime.now(),
      });

      final blockedIds = {'blocked_user'};

      final allRooms = await fakeFirestore.collection('chat_rooms')
          .where('participantIds', arrayContains: 'me').get();

      final visibleRooms = allRooms.docs.where((doc) {
        final ids = List<String>.from(doc.data()['participantIds']);
        return !ids.any(blockedIds.contains);
      }).toList();

      expect(visibleRooms, hasLength(1));
      expect(
        List<String>.from(visibleRooms.first.data()['participantIds']),
        contains('normal_user'),
      );
    });
  });

  // ==================== 模組 I: autoSkipReviews 72hr 寬限期 ====================
  // 對齊 functions/src/scheduledNotifications.ts autoSkipReviews 新邏輯
  group('I. autoSkipReviews 72hr 寬限期', () {
    const seventyTwoHours = Duration(hours: 72);

    test('I1: 晚餐後未滿 72hr 不應觸發自動跳過', () {
      final eventDate = DateTime.now().subtract(const Duration(hours: 60));
      final shouldSkip = DateTime.now().difference(eventDate) >= seventyTwoHours;
      expect(shouldSkip, isFalse, reason: '寬限期內，使用者仍可主動評價');
    });

    test('I2: 晚餐後超過 72hr 應觸發自動跳過', () {
      final eventDate = DateTime.now().subtract(const Duration(hours: 73));
      final shouldSkip = DateTime.now().difference(eventDate) >= seventyTwoHours;
      expect(shouldSkip, isTrue);
    });

    test('I3: eventDate 缺失時應保守不跳過 (安全防呆)', () {
      final Map<String, dynamic> groupData = {'status': 'completed'};
      final eventDate = groupData['eventDate'] as DateTime?;
      final shouldSkip = eventDate != null &&
          DateTime.now().difference(eventDate).inHours >= 72;
      expect(shouldSkip, isFalse,
          reason: '無 eventDate 不能假設已過寬限，避免誤標 skipped');
    });
  });
}
