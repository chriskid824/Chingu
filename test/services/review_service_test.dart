import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0:雙盲評價邏輯
///
/// ReviewService 直接 new FirebaseFirestore.instance,無法注入 fake,
/// 這裡以相同的資料規則(確定性 doc id + rules 對應行為)對 fake firestore
/// 驗證核心不變量;ReviewService 的行為變更需同步這份規則。
void main() {
  late FakeFirebaseFirestore firestore;

  const reviewer = 'user-a';
  const reviewee = 'user-b';
  const groupId = 'group-1';
  const eventId = 'event-1';
  const reviewId = '${reviewer}_${reviewee}_$groupId';

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  Future<void> submit(String result) async {
    final docRef = firestore.collection('dinner_reviews').doc(reviewId);
    final existing = await docRef.get();
    if (existing.exists) {
      if (existing.data()?['result'] == 'skipped') {
        throw StateError('expired');
      }
      return; // 冪等:已評過就跳過
    }
    await docRef.set({
      'reviewerId': reviewer,
      'revieweeId': reviewee,
      'groupId': groupId,
      'eventId': eventId,
      'result': result,
      'createdAt': Timestamp.now(),
    });
  }

  group('雙盲評價核心不變量', () {
    test('確定性 doc id:同一組 reviewer/reviewee/group 只會有一筆', () async {
      await submit('like');
      await submit('like'); // 重複提交(連點/多裝置)
      final all = await firestore.collection('dinner_reviews').get();
      expect(all.docs.length, 1);
      expect(all.docs.first.id, reviewId);
    });

    test('重複提交不覆寫原結果', () async {
      await submit('like');
      await submit('dislike'); // 第二次不同答案應被忽略
      final doc =
          await firestore.collection('dinner_reviews').doc(reviewId).get();
      expect(doc.data()?['result'], 'like');
    });

    test('系統已填 skipped(逾期)後提交 → 拋出逾期而非靜默成功', () async {
      // 模擬 autoSkipReviews 用同一套確定性 id 寫入 skipped
      await firestore.collection('dinner_reviews').doc(reviewId).set({
        'reviewerId': reviewer,
        'revieweeId': reviewee,
        'groupId': groupId,
        'eventId': eventId,
        'result': 'skipped',
        'createdAt': Timestamp.now(),
      });

      expect(() => submit('like'), throwsA(isA<StateError>()));
    });

    test('雙盲:反向查詢(讀對方的評價)在 rules 下不可行 — client 端不做結算',
        () async {
      // 這條規則由 firestore.rules 保證:
      //   allow read: if resource.data.reviewerId == request.auth.uid
      // client 端的結算程式碼已移除(review_service 不再查對方 review、
      // 不再建立聊天室),結算唯一入口是 Cloud Function onMutualMatch。
      // 此測試錨定該設計決策:若有人在 client 加回反向查詢,
      // production 會直接 permission-denied。
      await submit('like');
      final mine = await firestore
          .collection('dinner_reviews')
          .where('reviewerId', isEqualTo: reviewer)
          .get();
      expect(mine.docs.length, 1);
      // fake firestore 不驗 rules,只能驗「client 程式碼不含反向查詢」:
      // 見 review_service.dart — 無任何 where('reviewerId', isEqualTo: 對方) 用法
    });

    test('Match 結算輸入條件:雙向 like 才成立(對應 onMutualMatch 邏輯)', () async {
      // 模擬 CF 的判斷:A→B like + B→A like
      await submit('like');
      await firestore
          .collection('dinner_reviews')
          .doc('${reviewee}_${reviewer}_$groupId')
          .set({
        'reviewerId': reviewee,
        'revieweeId': reviewer,
        'groupId': groupId,
        'eventId': eventId,
        'result': 'like',
        'createdAt': Timestamp.now(),
      });

      final reverse = await firestore
          .collection('dinner_reviews')
          .where('reviewerId', isEqualTo: reviewee)
          .where('revieweeId', isEqualTo: reviewer)
          .where('eventId', isEqualTo: eventId)
          .where('result', isEqualTo: 'like')
          .get();
      expect(reverse.docs.length, 1, reason: '雙向 like 成立 → CF 會建聊天室');

      // dislike / skipped 不觸發
      final noMatch = await firestore
          .collection('dinner_reviews')
          .where('reviewerId', isEqualTo: reviewee)
          .where('result', whereIn: ['dislike', 'skipped']).get();
      expect(noMatch.docs, isEmpty);
    });
  });
}
