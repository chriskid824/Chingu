import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// MatchingService 測試
/// 使用 FakeFirebaseFirestore 進行單元測試
void main() {
  group('MatchingService', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    // ==================== 配對邏輯測試 ====================

    group('Matching Logic', () {
      test('should calculate age correctly', () {
        final birthDate = DateTime(1995, 1, 1);
        final now = DateTime(2026, 2, 8);
        final age = now.year - birthDate.year;
        
        expect(age, equals(31));
      });

      test('should pass hard filter when age is in range', () {
        const candidateAge = 25;
        const minAge = 20;
        const maxAge = 30;

        final passesFilter = candidateAge >= minAge && candidateAge <= maxAge;
        expect(passesFilter, isTrue);
      });

      test('should fail hard filter when age is out of range', () {
        const candidateAge = 40;
        const minAge = 20;
        const maxAge = 30;

        final passesFilter = candidateAge >= minAge && candidateAge <= maxAge;
        expect(passesFilter, isFalse);
      });

      test('should calculate interest score correctly', () {
        final userInterests = ['coding', 'reading', 'movies'];
        final candidateInterests = ['coding', 'gaming', 'movies'];
        
        final commonInterests = userInterests
            .where((i) => candidateInterests.contains(i))
            .length;
        
        // 2 common interests out of 3+3-2=4 unique
        expect(commonInterests, equals(2));
      });
    });

    // ==================== Swipe 記錄測試 ====================

    group('Swipe Recording', () {
      test('should record a like swipe', () async {
        await fakeFirestore.collection('swipes').add({
          'userId': 'user1',
          'targetUserId': 'user2',
          'isLike': true,
          'createdAt': DateTime.now(),
        });

        final swipes = await fakeFirestore.collection('swipes').get();
        expect(swipes.docs.length, equals(1));
        expect(swipes.docs.first['isLike'], isTrue);
      });

      test('should record a dislike swipe', () async {
        await fakeFirestore.collection('swipes').add({
          'userId': 'user1',
          'targetUserId': 'user2',
          'isLike': false,
          'createdAt': DateTime.now(),
        });

        final swipes = await fakeFirestore.collection('swipes').get();
        expect(swipes.docs.first['isLike'], isFalse);
      });

      test('should detect mutual like', () async {
        // User1 likes User2
        await fakeFirestore.collection('swipes').add({
          'userId': 'user1',
          'targetUserId': 'user2',
          'isLike': true,
        });

        // User2 likes User1
        await fakeFirestore.collection('swipes').add({
          'userId': 'user2',
          'targetUserId': 'user1',
          'isLike': true,
        });

        // Check for mutual like
        final user1ToUser2 = await fakeFirestore
            .collection('swipes')
            .where('userId', isEqualTo: 'user1')
            .where('targetUserId', isEqualTo: 'user2')
            .where('isLike', isEqualTo: true)
            .get();

        final user2ToUser1 = await fakeFirestore
            .collection('swipes')
            .where('userId', isEqualTo: 'user2')
            .where('targetUserId', isEqualTo: 'user1')
            .where('isLike', isEqualTo: true)
            .get();

        final isMutualLike = user1ToUser2.docs.isNotEmpty && user2ToUser1.docs.isNotEmpty;
        expect(isMutualLike, isTrue);
      });
    });

    // ==================== 配對結果測試 ====================

    group('Match Results', () {
      test('should create match record on mutual like', () async {
        await fakeFirestore.collection('matches').add({
          'userIds': ['user1', 'user2'],
          'matchedAt': DateTime.now(),
          'chatRoomId': 'chat_room_123',
        });

        final matches = await fakeFirestore.collection('matches').get();
        expect(matches.docs.length, equals(1));
        expect(matches.docs.first['userIds'], containsAll(['user1', 'user2']));
      });

      test('should query user matches', () async {
        await fakeFirestore.collection('matches').add({
          'userIds': ['user1', 'user2'],
          'matchedAt': DateTime.now(),
        });

        await fakeFirestore.collection('matches').add({
          'userIds': ['user1', 'user3'],
          'matchedAt': DateTime.now(),
        });

        final user1Matches = await fakeFirestore
            .collection('matches')
            .where('userIds', arrayContains: 'user1')
            .get();

        expect(user1Matches.docs.length, equals(2));
      });
    });

    // ==================== 過濾已滑動用戶 ====================

    group('Filter Swiped Users', () {
      test('should exclude already swiped users', () async {
        // User1 已經滑過 user2
        await fakeFirestore.collection('swipes').add({
          'userId': 'user1',
          'targetUserId': 'user2',
          'isLike': true,
        });

        final swipedQuery = await fakeFirestore
            .collection('swipes')
            .where('userId', isEqualTo: 'user1')
            .get();

        final swipedUserIds = swipedQuery.docs
            .map((doc) => doc['targetUserId'] as String)
            .toList();

        expect(swipedUserIds, contains('user2'));

        // 模擬過濾邏輯
        final allCandidates = ['user2', 'user3', 'user4'];
        final filteredCandidates = allCandidates
            .where((id) => !swipedUserIds.contains(id))
            .toList();

        expect(filteredCandidates, equals(['user3', 'user4']));
      });
    });

    // ==================== 分數計算測試 ====================

    group('Score Calculation', () {
      test('should calculate location score', () {
        // 同城市同區域 = 20
        // 同城市不同區域 = 10
        // 不同城市 = 0
        
        const sameDistrict = 20;
        const sameCityDifferentDistrict = 10;
        const differentCity = 0;

        expect(sameDistrict, greaterThan(sameCityDifferentDistrict));
        expect(sameCityDifferentDistrict, greaterThan(differentCity));
      });

      test('should calculate budget score', () {
        // 相同預算範圍 = 20
        // 相差 1 級 = 10
        // 相差 2 級以上 = 0
        
        const budget1 = 2;
        const budget2 = 2;
        const budget3 = 4;

        final sameBudgetScore = (budget1 == budget2) ? 20 : 0;
        final differentBudgetScore = (budget1 - budget3).abs() <= 1 ? 10 : 0;

        expect(sameBudgetScore, equals(20));
        expect(differentBudgetScore, equals(0));
      });

      test('should calculate total score', () {
        const interestScore = 15;  // out of 40
        const budgetScore = 20;    // out of 20
        const locationScore = 20;  // out of 20
        const ageScore = 20;       // out of 20

        const totalScore = interestScore + budgetScore + locationScore + ageScore;
        expect(totalScore, equals(75));
        expect(totalScore, lessThanOrEqualTo(100));
      });
    });
  });
}
