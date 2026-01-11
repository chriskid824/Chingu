import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/moment_model.dart';

/// Firestore 服務 - 處理所有 Firestore 數據操作
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');
  CollectionReference get _momentsCollection => _firestore.collection('moments');

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

  // === Moments Methods ===

  /// 創建新動態
  Future<void> createMoment(MomentModel moment) async {
    try {
      // If moment.id is empty, Firestore will generate one, but MomentModel.toMap might not handle it well if we expect ID in model
      // Usually we let Firestore generate ID
      final docRef = _momentsCollection.doc(); // Auto ID
      final momentWithId = moment.copyWith(id: docRef.id);
      await docRef.set(momentWithId.toMap());
    } catch (e) {
      throw Exception('創建動態失敗: $e');
    }
  }

  /// 獲取動態列表
  /// [limit] 限制數量
  /// [lastDocument] 上一頁最後一個文檔（用於分頁）
  /// [currentUserId] 當前用戶ID（用於判斷是否點讚）
  Future<List<MomentModel>> getMoments({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? currentUserId,
  }) async {
    try {
      Query query = _momentsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => MomentModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
                currentUserId: currentUserId,
              ))
          .toList();
    } catch (e) {
      throw Exception('獲取動態失敗: $e');
    }
  }

  /// 對動態點讚/取消點讚
  Future<void> toggleMomentLike(String momentId, String userId) async {
    final momentRef = _momentsCollection.doc(momentId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(momentRef);
        if (!snapshot.exists) {
          throw Exception("動態不存在");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final likes = List<String>.from(data['likes'] ?? []);
        final isLiked = likes.contains(userId);

        if (isLiked) {
          // Unlike
          transaction.update(momentRef, {
            'likes': FieldValue.arrayRemove([userId]),
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // Like
          transaction.update(momentRef, {
            'likes': FieldValue.arrayUnion([userId]),
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      throw Exception('點讚操作失敗: $e');
    }
  }

  /// 新增動態評論
  Future<void> addMomentComment(
      String momentId, String userId, String content) async {
    final momentRef = _momentsCollection.doc(momentId);
    final commentsRef = momentRef.collection('comments');

    try {
      await _firestore.runTransaction((transaction) async {
        // Create comment
        final commentRef = commentsRef.doc(); // Auto ID

        // Fetch user data for the comment (optional, or fetch on read)
        // Here we just store userId and let the client fetch user details or store basic info
        // To be simpler and faster, we usually fetch user info.
        // For now, let's assume we store minimal info or just userId.
        // To display name/avatar immediately, we might want to pass it or fetch it.
        // But the method signature only has userId.
        // Let's fetch user info inside transaction or before.
        // Since we are inside a service method, let's just use userId and content.
        // The display will have to handle fetching user data or we assume the caller provides it?
        // Let's fetch user data here to store in comment for easy display.

        final userDoc = await transaction.get(_usersCollection.doc(userId));
        if (!userDoc.exists) throw Exception("用戶不存在");
        final userData = userDoc.data() as Map<String, dynamic>;

        transaction.set(commentRef, {
          'userId': userId,
          'userName': userData['name'] ?? 'Unknown',
          'userAvatar': userData['avatarUrl'],
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Increment comment count
        transaction.update(momentRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (e) {
      throw Exception('新增評論失敗: $e');
    }
  }

  /// 獲取動態評論流
  Stream<List<Map<String, dynamic>>> getMomentComments(String momentId) {
    return _momentsCollection
        .doc(momentId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        // Convert Timestamp to DateTime
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return data;
      }).toList();
    });
  }
}
