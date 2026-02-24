import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/report_model.dart';

/// 舉報與封鎖服務
/// 
/// 提供用戶舉報和封鎖功能，這是 App Store 社交類 App 審核的必要功能。
class ReportBlockService {
  final FirebaseFirestore _firestore;

  ReportBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 舉報集合引用
  CollectionReference get _reportsCollection => _firestore.collection('reports');

  /// 用戶集合引用
  CollectionReference get _usersCollection => _firestore.collection('users');

  // ==================== 舉報功能 ====================

  /// 舉報用戶
  ///
  /// [reporterId] 舉報者 ID
  /// [reportedUserId] 被舉報者 ID
  /// [reason] 舉報原因
  /// [description] 詳細描述（可選）
  Future<void> reportUser({
    required String reporterId,
    required String reportedUserId,
    required ReportReason reason,
    String? description,
  }) async {
    try {
      // 檢查是否已經舉報過（避免重複舉報）
      final existingReport = await _reportsCollection
          .where('reporterId', isEqualTo: reporterId)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('您已經舉報過此用戶，請等待處理');
      }

      await _reportsCollection.add({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason.value,
        'description': description,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('舉報失敗: $e');
    }
  }

  /// 獲取用戶的舉報記錄
  Future<List<ReportModel>> getUserReports(String userId) async {
    try {
      final query = await _reportsCollection
          .where('reporterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('獲取舉報記錄失敗: $e');
    }
  }

  // ==================== 封鎖功能 ====================

  /// 封鎖用戶
  ///
  /// [userId] 操作者 ID
  /// [blockedUserId] 被封鎖者 ID
  Future<void> blockUser(String userId, String blockedUserId) async {
    try {
      await _usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayUnion([blockedUserId]),
      });
    } catch (e) {
      // 如果欄位不存在，使用 set with merge
      await _usersCollection.doc(userId).set({
        'blockedUserIds': [blockedUserId],
      }, SetOptions(merge: true));
    }
  }

  /// 解除封鎖用戶
  ///
  /// [userId] 操作者 ID
  /// [blockedUserId] 被封鎖者 ID
  Future<void> unblockUser(String userId, String blockedUserId) async {
    try {
      await _usersCollection.doc(userId).update({
        'blockedUserIds': FieldValue.arrayRemove([blockedUserId]),
      });
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 獲取封鎖用戶 ID 列表
  ///
  /// [userId] 用戶 ID
  /// 返回被封鎖的用戶 ID 列表
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return [];

      return List<String>.from(data['blockedUserIds'] ?? []);
    } catch (e) {
      print('獲取封鎖列表失敗: $e');
      return [];
    }
  }

  /// 檢查是否已封鎖
  ///
  /// [userId] 檢查者 ID
  /// [targetUserId] 目標用戶 ID
  /// 
  /// 如果 userId 封鎖了 targetUserId，返回 true
  Future<bool> isBlocked(String userId, String targetUserId) async {
    final blockedIds = await getBlockedUserIds(userId);
    return blockedIds.contains(targetUserId);
  }

  /// 檢查雙向封鎖（任一方封鎖另一方）
  ///
  /// [userId1] 用戶 1 ID
  /// [userId2] 用戶 2 ID
  ///
  /// 如果任一方封鎖了對方，返回 true
  Future<bool> isEitherBlocked(String userId1, String userId2) async {
    final blocked1 = await isBlocked(userId1, userId2);
    if (blocked1) return true;
    
    final blocked2 = await isBlocked(userId2, userId1);
    return blocked2;
  }

  /// 封鎖並舉報用戶（常見的組合操作）
  ///
  /// [reporterId] 舉報者 ID
  /// [reportedUserId] 被舉報者 ID
  /// [reason] 舉報原因
  /// [description] 詳細描述（可選）
  Future<void> blockAndReport({
    required String reporterId,
    required String reportedUserId,
    required ReportReason reason,
    String? description,
  }) async {
    await blockUser(reporterId, reportedUserId);
    await reportUser(
      reporterId: reporterId,
      reportedUserId: reportedUserId,
      reason: reason,
      description: description,
    );
  }
}
