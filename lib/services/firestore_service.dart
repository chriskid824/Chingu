import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';

/// Firestore 服務 - 處理所有 Firestore 數據操作
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 創建新用戶資料
  /// 
  /// [userModel] 用戶模型
  Future<void> createUser(UserModel userModel) async {
    try {
      await _usersCollection.doc(userModel.uid).set(userModel.toMap());
    } catch (e) {
      throw Exception('創建用戶資料失敗: $e');
    }
  }

  /// 獲取用戶資料
  /// 
  /// [uid] 用戶 ID
  /// 返回 UserModel 或 null
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('獲取用戶資料失敗: $e');
    }
  }

  /// 更新用戶資料
  /// 
  /// [uid] 用戶 ID
  /// [data] 要更新的資料
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      // 添加更新時間
      data['updatedAt'] = FieldValue.serverTimestamp();

      // 使用 set with merge 來確保即使文檔不存在也能創建
      await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('更新用戶資料失敗: $e');
    }
  }

  /// 刪除用戶資料
  /// 
  /// [uid] 用戶 ID
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('刪除用戶資料失敗: $e');
    }
  }

  /// 檢查用戶是否存在
  /// 
  /// [uid] 用戶 ID
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('檢查用戶失敗: $e');
    }
  }

  /// 監聽用戶資料變化
  /// 
  /// [uid] 用戶 ID
  /// 返回 UserModel 流
  Stream<UserModel?> getUserStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    });
  }

  /// 更新最後登入時間
  /// 
  /// [uid] 用戶 ID
  Future<void> updateLastLogin(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('更新登入時間失敗: $e');
    }
  }

  /// 查詢符合條件的用戶（用於配對）
  /// 
  /// [city] 城市
  /// [budgetRange] 預算範圍
  /// [gender] 性別（可選）
  /// [minAge] 最小年齡（可選）
  /// [maxAge] 最大年齡（可選）
  /// [limit] 返回數量限制
  Future<List<UserModel>> queryMatchingUsers({
    required String city,
    int? budgetRange, // 改為可選，且不強制過濾
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) async {
    try {
      print('=== FirestoreService.queryMatchingUsers ===');
      print('查詢城市: $city');
      print('limit: $limit');
      
      // 放寬查詢條件：只過濾城市和活躍狀態
      // 預算和其他條件在內存中進行評分和過濾
      Query query = _usersCollection
          .where('city', isEqualTo: city)
          .where('isActive', isEqualTo: true)
          .limit(limit);

      final querySnapshot = await query.get();
      print('Firestore 查詢返回 ${querySnapshot.docs.length} 個文檔');

      List<UserModel> users = querySnapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      print('成功解析 ${users.length} 個 UserModel');
      if (users.isNotEmpty) {
        print('第一個用戶: ${users.first.name}, 城市: ${users.first.city}');
      }

      // 在客戶端進行額外的過濾（因為 Firestore 查詢限制）
      if (gender != null) {
        users = users.where((user) => user.gender == gender).toList();
      }

      if (minAge != null && maxAge != null) {
        users = users
            .where((user) => user.age >= minAge && user.age <= maxAge)
            .toList();
      }

      print('過濾後剩餘 ${users.length} 個用戶');
      return users;
    } catch (e) {
      print('FirestoreService.queryMatchingUsers 錯誤: $e');
      throw Exception('查詢用戶失敗: $e');
    }
  }

  /// 批次獲取用戶資料
  /// 
  /// [uids] 用戶 ID 列表
  Future<List<UserModel>> getBatchUsers(List<String> uids) async {
    try {
      if (uids.isEmpty) return [];

      // Firestore 的 'in' 查詢最多支持 10 個元素
      // 如果超過 10 個，需要分批查詢
      List<UserModel> allUsers = [];

      for (int i = 0; i < uids.length; i += 10) {
        final batchUids = uids.skip(i).take(10).toList();

        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batchUids)
            .get();

        final batchUsers = querySnapshot.docs
            .map((doc) =>
                UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        allUsers.addAll(batchUsers);
      }

      return allUsers;
    } catch (e) {
      throw Exception('批次獲取用戶失敗: $e');
    }
  }

  /// 搜尋用戶（by 名稱）
  /// 
  /// [searchTerm] 搜尋詞
  /// [limit] 返回數量限制
  Future<List<UserModel>> searchUsers(String searchTerm,
      {int limit = 20}) async {
    try {
      // 注意：此搜尋方法較簡單，實際應用中建議使用 Algolia 等專業搜尋服務
      final querySnapshot = await _usersCollection
          .where('name', isGreaterThanOrEqualTo: searchTerm)
          .where('name', isLessThan: '${searchTerm}z')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('搜尋用戶失敗: $e');
    }
  }

  /// 更新用戶統計資料
  /// 
  /// [uid] 用戶 ID
  /// [totalDinners] 參加晚餐總數增量
  /// [totalMatches] 配對總數增量
  Future<void> updateUserStats(
    String uid, {
    int? totalDinners,
    int? totalMatches,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (totalDinners != null) {
        updates['totalDinners'] = FieldValue.increment(totalDinners);
      }

      if (totalMatches != null) {
        updates['totalMatches'] = FieldValue.increment(totalMatches);
      }

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('更新用戶統計失敗: $e');
    }
  }

  /// 更新用戶平均評分
  /// 
  /// [uid] 用戶 ID
  /// [newRating] 新評分
  Future<void> updateUserRating(String uid, double newRating) async {
    try {
      final user = await getUser(uid);
      if (user == null) return;

      final totalRatings =
          user.totalDinners; // 假設每次晚餐都會被評分
      final currentAverage = user.averageRating;
      final newAverage =
          ((currentAverage * (totalRatings - 1)) + newRating) / totalRatings;

      await updateUser(uid, {'averageRating': newAverage});
    } catch (e) {
      throw Exception('更新用戶評分失敗: $e');
    }
  }

  /// 提交用戶舉報
  Future<void> submitUserReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending', // pending, reviewed, resolved
        'type': 'user_report',
      });
    } catch (e) {
      throw Exception('提交舉報失敗: $e');
    }
  }

  /// 請求資料導出
  Future<void> requestDataExport(String uid) async {
    try {
      await _firestore.collection('data_export_requests').add({
        'uid': uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('請求資料導出失敗: $e');
    }
  }

  /// 刪除用戶及其相關資料
  Future<void> deleteUserAndRelatedData(String uid) async {
    try {
      final batch = _firestore.batch();

      // 1. 刪除用戶文檔
      batch.delete(_usersCollection.doc(uid));

      // 2. 標記相關的 Chat Rooms 為失效或移除用戶
      // 注意：直接刪除可能會影響其他用戶的聊天記錄，更好的做法是將用戶從 participantIds 移除
      // 但如果這是嚴格的"刪除資料"請求，我們應該刪除所有相關數據。
      // 這裡採用移除 participantIds 的策略，如果只剩一個用戶，則聊天室可能需要被清理（由後端函數處理）
      // 或者直接刪除參與者是該用戶的聊天室記錄（如果我們只關心該用戶的關聯）

      // 為了簡化和確保數據清除，我們查找該用戶參與的聊天室
      final chatRoomsSnapshot = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: uid)
          .get();

      for (var doc in chatRoomsSnapshot.docs) {
        // 從參與者中移除
        batch.update(doc.reference, {
          'participantIds': FieldValue.arrayRemove([uid]),
          // 清除該用戶的未讀計數
          'unreadCount.$uid': FieldValue.delete(),
          // 清除打字狀態
          'typingIndicators.$uid': FieldValue.delete(),
        });
      }

      // 3. 刪除用戶的 Swipes
      final swipesSnapshot = await _firestore
          .collection('swipes')
          .where('swiperId', isEqualTo: uid)
          .get();

      for (var doc in swipesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 4. 刪除用戶的 Reports (作為 reporter)
      final reportsSnapshot = await _firestore
          .collection('reports')
          .where('reporterId', isEqualTo: uid)
          .get();

      for (var doc in reportsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 注意：Messages 集合如果是頂層集合且量大，客戶端刪除可能不切實際且昂貴。
      // 通常這部分由雲端函數 (Cloud Functions) 響應 auth.user().onDelete 事件來處理。
      // 在此僅作基本清理。

      // 5. 提交 Batch
      await batch.commit();

    } catch (e) {
      throw Exception('刪除用戶相關資料失敗: $e');
    }
  }
}


