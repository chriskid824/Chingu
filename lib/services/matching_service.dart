import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

import 'package:chingu/services/chat_service.dart';

/// 配對服務 - 處理用戶配對邏輯、推薦與滑動記錄
class MatchingService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;
  final ChatService _chatService;

  MatchingService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
    ChatService? chatService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService(),
        _chatService = chatService ?? ChatService();

  /// 滑動記錄集合引用
  CollectionReference get _swipesCollection => _firestore.collection('swipes');

  /// 獲取推薦的配對用戶
  ///
  /// [currentUser] 當前用戶模型
  /// [limit] 返回的最大數量，預設為 10
  ///
  /// 返回包含 'user' (UserModel) 和 'score' (int) 的 Map 列表
  Future<List<Map<String, dynamic>>> getMatches(UserModel currentUser, {int limit = 10}) async {
    try {
      print('=== MatchingService.getMatches 開始 ===');
      print('當前用戶: ${currentUser.name}');
      print('城市: ${currentUser.city}');
      print('性別: ${currentUser.gender}');
      print('性別偏好: ${currentUser.preferredMatchType}');
      
      // 1. 獲取所有潛在候選人 (同城市)
      print('開始查詢 Firestore...');
      final candidates = await _firestoreService.queryMatchingUsers(
        city: currentUser.city,
        // budgetRange: currentUser.budgetRange, // 不再強制過濾預算
        limit: 50, // 獲取較多候選人進行內存過濾
      );

      print('從 Firestore 獲得 ${candidates.length} 個用戶');

      // 2. 獲取已滑過的用戶 ID (喜歡或不喜歡)
      final swipedIds = await _getSwipedUserIds(currentUser.uid);
      print('已滑過 ${swipedIds.length} 個用戶');

      // 3. 過濾和評分
      List<Map<String, dynamic>> scoredMatches = [];

      for (var candidate in candidates) {
        // 排除自己
        if (candidate.uid == currentUser.uid) {
          print('跳過: 自己 (${candidate.name})');
          continue;
        }

        // 排除已封鎖或封鎖我的用戶
        if (currentUser.blockedUserIds.contains(candidate.uid)) {
          print('跳過: 已封鎖 (${candidate.name})');
          continue;
        }
        if (candidate.blockedUserIds.contains(currentUser.uid)) {
          print('跳過: 被封鎖 (${candidate.name})');
          continue;
        }

        // 排除已滑過的
        if (swipedIds.contains(candidate.uid)) {
          print('跳過: 已滑過 (${candidate.name})');
          continue;
        }

        // 硬性條件過濾
        if (!_passesHardFilters(currentUser, candidate)) {
          print('跳過: 不符合硬性條件 (${candidate.name}, 性別: ${candidate.gender}, 年齡: ${candidate.age})');
          continue;
        }

        // 計算匹配分數
        final score = _calculateMatchScore(currentUser, candidate);

        print('加入候選人: ${candidate.name}, 分數: $score');
        scoredMatches.add({
          'user': candidate,
          'score': score,
        });
      }

      print('過濾後剩餘 ${scoredMatches.length} 個候選人');

      // 4. 排序 (分數高到低)
      scoredMatches.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      // 5. 返回前 N 個
      final result = scoredMatches.take(limit).toList();
      print('最終返回 ${result.length} 個候選人');
      return result;
    } catch (e) {
      print('MatchingService.getMatches 錯誤: $e');
      throw Exception('獲取配對失敗: $e');
    }
  }

  /// 記錄滑動操作 (喜歡/不喜歡)
  ///
  /// [userId] 操作用戶 ID
  /// [targetUserId] 被滑動的目標用戶 ID
  /// [isLike] 是否喜歡 (true: 喜歡, false: 不喜歡/跳過)
  ///
  /// 返回配對結果: { 'isMatch': bool, 'chatRoomId': String?, 'partner': UserModel? }
  Future<Map<String, dynamic>> recordSwipe(String userId, String targetUserId, bool isLike) async {
    try {
      await _swipesCollection.add({
        'userId': userId,
        'targetUserId': targetUserId,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 如果是喜歡，檢查是否配對成功 (對方也喜歡我)
      if (isLike) {
        final isMatch = await _checkMutualMatch(userId, targetUserId);
        if (isMatch) {
          final chatRoomId = await _handleMatchSuccess(userId, targetUserId);
          
          // 獲取對方資料以返回
          final partnerDoc = await _firestore.collection('users').doc(targetUserId).get();
          final partner = UserModel.fromMap(partnerDoc.data()!, targetUserId);
          
          return {
            'isMatch': true,
            'chatRoomId': chatRoomId,
            'partner': partner,
          };
        }
      }
      
      return {
        'isMatch': false,
        'chatRoomId': null,
        'partner': null,
      };
    } catch (e) {
      throw Exception('記錄滑動失敗: $e');
    }
  }

  /// 檢查是否雙向配對成功 (私有方法)
  ///
  /// [userId] 用戶 A ID
  /// [targetUserId] 用戶 B ID
  ///
  /// 如果雙方互相關注則返回 true
  Future<bool> _checkMutualMatch(String userId, String targetUserId) async {
    try {
      // 檢查對方是否已經喜歡我
      final query = await _swipesCollection
          .where('userId', isEqualTo: targetUserId)
          .where('targetUserId', isEqualTo: userId)
          .where('isLike', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        // 配對成功！
        return true;
      }
      return false;
    } catch (e) {
      print('檢查配對失敗: $e');
      return false;
    }
  }

  /// 處理配對成功
  ///
  /// [user1Id] 用戶 1 ID
  /// [user2Id] 用戶 2 ID
  ///
  /// 返回新創建的聊天室 ID
  Future<String> _handleMatchSuccess(String user1Id, String user2Id) async {
    // 更新雙方的 totalMatches
    await _firestoreService.updateUserStats(user1Id, totalMatches: 1);
    await _firestoreService.updateUserStats(user2Id, totalMatches: 1);
    
    // 創建聊天室
    return await _chatService.createChatRoom(user1Id, user2Id);
  }

  /// 獲取已滑過的用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  /// 返回已滑過的目標用戶 ID 列表
  Future<List<String>> _getSwipedUserIds(String userId) async {
    final query = await _swipesCollection.where('userId', isEqualTo: userId).get();
    return query.docs.map((doc) => doc['targetUserId'] as String).toList();
  }

  /// 硬性條件過濾 (性別、年齡)
  ///
  /// [current] 當前用戶
  /// [candidate] 候選用戶
  ///
  /// 如果符合硬性條件返回 true
  bool _passesHardFilters(UserModel current, UserModel candidate) {
    // 性別偏好過濾
    if (current.preferredMatchType == 'opposite') {
      if (current.gender == candidate.gender) return false;
    } else if (current.preferredMatchType == 'same') {
      if (current.gender != candidate.gender) return false;
    }
    // 'any' 則不過濾性別

    // 年齡範圍過濾
    if (candidate.age < current.minAge || candidate.age > current.maxAge) {
      return false;
    }

    return true;
  }

  /// 計算匹配分數 (0-100)
  ///
  /// [current] 當前用戶
  /// [candidate] 候選用戶
  ///
  /// 返回匹配分數
  int _calculateMatchScore(UserModel current, UserModel candidate) {
    double score = 0;

    // 1. 興趣匹配 (50%) - 提高權重，強調共同話題
    // 計算共同興趣數量
    final commonInterests = current.interests.where((i) => candidate.interests.contains(i)).length;
    // 假設如果有 4 個共同興趣就拿滿分 (從 3 提高到 4)
    final interestScore = (commonInterests / 4).clamp(0.0, 1.0) * 50;
    score += interestScore;

    // 2. 地點匹配 (30%) - 提高權重，強調地理位置便利性
    if (current.city == candidate.city) {
      if (current.district == candidate.district) {
        score += 30; // 同區滿分
      } else {
        score += 15; // 同城市不同區給一半
      }
    }

    // 3. 年齡匹配 (10%) - 動態評分，越接近用戶年齡越高分
    final ageDiff = (current.age - candidate.age).abs();
    if (ageDiff <= 2) {
      score += 10; // 差距 2 歲以內
    } else if (ageDiff <= 5) {
      score += 5; // 差距 5 歲以內
    } else {
      score += 2; // 符合硬性篩選範圍但差距較大
    }

    // 4. 預算匹配 (10%) - 降低權重
    if (current.budgetRange == candidate.budgetRange) {
      score += 10;
    } else if ((current.budgetRange - candidate.budgetRange).abs() == 1) {
      score += 5; // 相鄰預算區間
    }

    return score.round();
  }

  /// 清除該用戶的所有滑動記錄 (重置配對歷史)
  ///
  /// 僅用於開發測試或用戶重置功能
  ///
  /// [userId] 用戶 ID
  Future<void> clearSwipeHistory(String userId) async {
    try {
      final batch = _firestore.batch();
      
      // 1. 刪除該用戶的主動滑動記錄
      final mySwipes = await _swipesCollection.where('userId', isEqualTo: userId).get();
      for (var doc in mySwipes.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      print('已清除用戶 $userId 的 ${mySwipes.docs.length} 條滑動記錄');
    } catch (e) {
      throw Exception('清除滑動記錄失敗: $e');
    }
  }
}

