import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_review_model.dart';

/// 評價已逾期(72 小時視窗結束,系統已自動填入 skipped)
class ReviewExpiredException implements Exception {
  @override
  String toString() => '評價時間已截止';
}

/// 評價服務 — 處理晚餐後雙盲互評
///
/// 流程:
/// 1. 晚餐結束後,每位參與者對同桌者做 👍/👎 評價
/// 2. 雙向 Match 的結算在 Cloud Function `onMutualMatch`(dinner_reviews
///    onCreate trigger)完成 — firestore.rules 的雙盲限制讓 client 讀不到
///    對方的評價,結算與聊天室建立一律交給 server 端
/// 3. 72 小時未評價由排程自動視為「跳過」(skipped)
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _reviewsCollection =>
      _firestore.collection('dinner_reviews');

  /// 提交評價
  ///
  /// [result] 為 'like'(👍)或 'dislike'(👎)
  /// doc id 用確定性規則(reviewer_reviewee_group),重複提交天然冪等;
  /// 若系統已自動填入 skipped(逾期),丟出 [ReviewExpiredException]。
  Future<void> submitReview({
    required String reviewerId,
    required String revieweeId,
    required String groupId,
    required String eventId,
    required String result,
  }) async {
    final reviewId = '${reviewerId}_${revieweeId}_$groupId';
    final docRef = _reviewsCollection.doc(reviewId);

    // 1. 檢查是否已評價過(只讀自己寫的,符合雙盲 rules)
    final existing = await docRef.get();
    if (existing.exists) {
      final existingResult =
          (existing.data() as Map<String, dynamic>?)?['result'];
      if (existingResult == 'skipped') {
        // 逾期已被系統結算,這次的選擇不能靜默吞掉
        throw ReviewExpiredException();
      }
      debugPrint('已評價過此人，跳過');
      return;
    }

    // 2. 建立評價(評價不可修改,rules 擋 update)
    final review = DinnerReviewModel(
      id: reviewId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      groupId: groupId,
      eventId: eventId,
      result: result,
      createdAt: DateTime.now(),
    );

    await docRef.set(review.toMap());
  }

  /// 取得某用戶在某群組的所有評價
  Future<List<DinnerReviewModel>> getReviewsByUser({
    required String userId,
    required String groupId,
  }) async {
    try {
      final snapshot = await _reviewsCollection
          .where('reviewerId', isEqualTo: userId)
          .where('groupId', isEqualTo: groupId)
          .get();

      return snapshot.docs
          .map((doc) =>
              DinnerReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('查詢評價失敗: $e');
    }
  }

  /// 檢查用戶是否已完成某群組的所有評價
  Future<bool> hasCompletedReviews({
    required String userId,
    required String groupId,
    required int totalMembers,
  }) async {
    final reviews = await getReviewsByUser(userId: userId, groupId: groupId);
    return reviews.length >= totalMembers - 1;
  }

  /// 取得待評價的群組列表（晚餐結束但未完成評價）
  Future<List<Map<String, dynamic>>> getPendingReviewGroups(String userId) async {
    try {
      final groupsSnapshot = await _firestore
          .collection('dinner_groups')
          .where('participantIds', arrayContains: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final pendingGroups = <Map<String, dynamic>>[];

      for (final doc in groupsSnapshot.docs) {
        final data = doc.data();
        // 評價已整組結算(逾期 autoSkip)的略過;client 端過濾避免新複合索引
        if (data['reviewStatus'] == 'completed') continue;
        final memberIds = List<String>.from(data['participantIds'] ?? []);
        final totalMembers = memberIds.length;

        final existingReviews = await getReviewsByUser(
          userId: userId,
          groupId: doc.id,
        );

        if (existingReviews.length >= totalMembers - 1) continue;

        final reviewedIds = existingReviews.map((r) => r.revieweeId).toSet();
        final pendingReviewees = memberIds
            .where((id) => id != userId && !reviewedIds.contains(id))
            .toList();

        pendingGroups.add({
          'groupId': doc.id,
          'eventId': data['eventId'] ?? '',
          'memberIds': memberIds,
          'pendingReviewees': pendingReviewees,
          'completedCount': existingReviews.length,
          'totalToReview': totalMembers - 1,
        });
      }

      return pendingGroups;
    } catch (e) {
      debugPrint('查詢待評價群組失敗: $e');
      return [];
    }
  }
}
