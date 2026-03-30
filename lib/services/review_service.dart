import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_review_model.dart';
import 'package:uuid/uuid.dart';

/// 評價服務 — 處理晚餐後雙盲互評與 Mutual Match 偵測
///
/// 流程：
/// 1. 晚餐結束後，每位參與者對同桌者做 👍/👎 評價
/// 2. 系統即時偵測雙向 Match（A 給 B 👍，且 B 也給 A 👍）
/// 3. Match 成功時立刻建立一對一聊天室
/// 4. 72 小時未評價自動視為「跳過」
class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _reviewsCollection =>
      _firestore.collection('dinner_reviews');

  CollectionReference get _chatRoomsCollection =>
      _firestore.collection('chat_rooms');

  /// 提交評價
  ///
  /// [result] 為 'like'（👍）或 'dislike'（👎）
  /// 回傳：如果偵測到 Mutual Match，回傳新建的 chatRoomId；否則回傳 null
  Future<String?> submitReview({
    required String reviewerId,
    required String revieweeId,
    required String groupId,
    required String eventId,
    required String result,
  }) async {
    try {
      // 1. 檢查是否已評價過
      final existing = await _reviewsCollection
          .where('reviewerId', isEqualTo: reviewerId)
          .where('revieweeId', isEqualTo: revieweeId)
          .where('groupId', isEqualTo: groupId)
          .get();

      if (existing.docs.isNotEmpty) {
        debugPrint('已評價過此人，跳過');
        return null;
      }

      // 2. 建立評價
      final reviewId = _uuid.v4();
      final review = DinnerReviewModel(
        id: reviewId,
        reviewerId: reviewerId,
        revieweeId: revieweeId,
        groupId: groupId,
        eventId: eventId,
        result: result,
        createdAt: DateTime.now(),
      );

      await _reviewsCollection.doc(reviewId).set(review.toMap());

      // 3. 如果給了 👍，即時檢查對方是否也給了 👍
      if (result == 'like') {
        return await _checkAndCreateMutualMatch(
          userA: reviewerId,
          userB: revieweeId,
          groupId: groupId,
          eventId: eventId,
        );
      }

      return null;
    } catch (e) {
      throw Exception('提交評價失敗: $e');
    }
  }

  /// 檢查雙向 Match 並建立一對一聊天室
  Future<String?> _checkAndCreateMutualMatch({
    required String userA,
    required String userB,
    required String groupId,
    required String eventId,
  }) async {
    // 查詢對方是否也給了 👍
    final reverseReview = await _reviewsCollection
        .where('reviewerId', isEqualTo: userB)
        .where('revieweeId', isEqualTo: userA)
        .where('groupId', isEqualTo: groupId)
        .where('result', isEqualTo: 'like')
        .get();

    if (reverseReview.docs.isEmpty) {
      return null; // 對方尚未評價或給了 👎
    }

    // Mutual Match! 建立一對一聊天室
    return await _createDirectChatRoom(
      userA: userA,
      userB: userB,
      groupId: groupId,
      eventId: eventId,
    );
  }

  /// 建立 Mutual Match 一對一聊天室
  Future<String> _createDirectChatRoom({
    required String userA,
    required String userB,
    required String groupId,
    required String eventId,
  }) async {
    // 用排序後的 UID 組合作為 ID，確保不重複
    final sortedIds = [userA, userB]..sort();
    final chatRoomId = '${sortedIds[0]}_${sortedIds[1]}_$groupId';

    final existingRoom = await _chatRoomsCollection.doc(chatRoomId).get();
    if (existingRoom.exists) {
      return chatRoomId;
    }

    await _chatRoomsCollection.doc(chatRoomId).set({
      'id': chatRoomId,
      'type': 'direct',
      'participantIds': sortedIds,
      'groupId': groupId,
      'dinnerEventId': eventId,
      'participantNames': {},
      'participantAvatars': {},
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': null,
      'lastMessageTime': null,
      'lastMessageSenderId': null,
      'unreadCount': {sortedIds[0]: 0, sortedIds[1]: 0},
    });

    debugPrint('Mutual Match! 一對一聊天室已建立: $chatRoomId');
    return chatRoomId;
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
        final memberIds = List<String>.from(data['participantIds'] ?? []);
        final totalMembers = memberIds.length;

        final hasCompleted = await hasCompletedReviews(
          userId: userId,
          groupId: doc.id,
          totalMembers: totalMembers,
        );

        if (!hasCompleted) {
          final existingReviews = await getReviewsByUser(
            userId: userId,
            groupId: doc.id,
          );
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
      }

      return pendingGroups;
    } catch (e) {
      debugPrint('查詢待評價群組失敗: $e');
      return [];
    }
  }
}
