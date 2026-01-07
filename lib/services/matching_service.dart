import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';

import 'package:chingu/services/chat_service.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ChatService _chatService = ChatService();

  // 記錄喜歡/不喜歡的集合
  CollectionReference get _swipesCollection => _firestore.collection('swipes');

  /// 獲取推薦的配對用戶
  ///
  /// [currentUser] 當前用戶
  /// [limit] 限制數量
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

  /// 檢查是否雙向配對成功
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
        // 配對成功！創建聊天室或發送通知
        await _handleMatchSuccess(userId, targetUserId);
        return true;
      }
      return false;
    } catch (e) {
      print('檢查配對失敗: $e');
      return false;
    }
  }

  /// 處理配對成功
  /// 返回新創建的聊天室 ID
  Future<String> _handleMatchSuccess(String user1Id, String user2Id) async {
    // 更新雙方的 totalMatches
    await _firestoreService.updateUserStats(user1Id, totalMatches: 1);
    await _firestoreService.updateUserStats(user2Id, totalMatches: 1);
    
    // 創建聊天室
    return await _chatService.createChatRoom(user1Id, user2Id);
  }

  /// 獲取已滑過的用戶 ID 列表
  Future<List<String>> _getSwipedUserIds(String userId) async {
    final query = await _swipesCollection.where('userId', isEqualTo: userId).get();
    return query.docs.map((doc) => doc['targetUserId'] as String).toList();
  }

  /// 硬性條件過濾 (性別、年齡)
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
  int _calculateMatchScore(UserModel current, UserModel candidate) {
    double score = 0;

    // 1. 興趣匹配 (40%)
    // 計算共同興趣數量
    final commonInterests = current.interests.where((i) => candidate.interests.contains(i)).length;
    // 假設如果有 3 個共同興趣就拿滿分
    final interestScore = (commonInterests / 3).clamp(0.0, 1.0) * 40;
    score += interestScore;

    // 2. 預算匹配 (20%)
    if (current.budgetRange == candidate.budgetRange) {
      score += 20;
    } else if ((current.budgetRange - candidate.budgetRange).abs() == 1) {
      score += 10; // 相鄰預算區間給一半分數
    }

    // 3. 地點匹配 (20%)
    if (current.city == candidate.city) {
      if (current.district == candidate.district) {
        score += 20;
      } else {
        score += 10; // 同城市不同區
      }
    }

    // 4. 年齡偏好匹配 (20%)
    // 已經在硬性條件過濾過了，這裡給予基礎分，越接近中間值越高分（可選）
    score += 20; 

    return score.round();
  }
}


