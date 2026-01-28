import 'package:cloud_firestore/cloud_firestore.dart';

/// 封鎖服務 - 處理用戶封鎖相關功能
class UserBlockService {
  final FirebaseFirestore _firestore;

  UserBlockService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 封鎖用戶
  ///
  /// [currentUid] 當前用戶 ID
  /// [targetUid] 目標用戶 ID
  Future<void> blockUser(String currentUid, String targetUid) async {
    try {
      final batch = _firestore.batch();

      // 1. 在當前用戶的封鎖列表中添加目標用戶
      final blockRef = _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blocks')
          .doc(targetUid);

      batch.set(blockRef, {
        'blockedAt': FieldValue.serverTimestamp(),
      });

      // 2. 在目標用戶的被封鎖列表中添加當前用戶 (用於雙向隱藏)
      final blockedByRef = _firestore
          .collection('users')
          .doc(targetUid)
          .collection('blocked_by')
          .doc(currentUid);

      batch.set(blockedByRef, {
        'blockedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('封鎖用戶失敗: $e');
    }
  }

  /// 解除封鎖
  ///
  /// [currentUid] 當前用戶 ID
  /// [targetUid] 目標用戶 ID
  Future<void> unblockUser(String currentUid, String targetUid) async {
    try {
      final batch = _firestore.batch();

      // 1. 移除封鎖記錄
      final blockRef = _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blocks')
          .doc(targetUid);

      batch.delete(blockRef);

      // 2. 移除被封鎖記錄
      final blockedByRef = _firestore
          .collection('users')
          .doc(targetUid)
          .collection('blocked_by')
          .doc(currentUid);

      batch.delete(blockedByRef);

      await batch.commit();
    } catch (e) {
      throw Exception('解除封鎖失敗: $e');
    }
  }

  /// 檢查是否已封鎖某用戶
  ///
  /// [currentUid] 當前用戶 ID
  /// [targetUid] 目標用戶 ID
  Future<bool> isBlocked(String currentUid, String targetUid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUid)
          .collection('blocks')
          .doc(targetUid)
          .get();

      return doc.exists;
    } catch (e) {
      throw Exception('檢查封鎖狀態失敗: $e');
    }
  }

  /// 獲取所有已封鎖的用戶 ID
  ///
  /// [uid] 用戶 ID
  Future<List<String>> getBlockedUserIds(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocks')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('獲取封鎖名單失敗: $e');
      return [];
    }
  }

  /// 獲取所有封鎖了當前用戶的用戶 ID
  ///
  /// [uid] 用戶 ID
  Future<List<String>> getBlockedByUserIds(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('blocked_by')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('獲取被封鎖名單失敗: $e');
      return [];
    }
  }

  /// 獲取所有需要排除的用戶 ID (包含我封鎖的人和封鎖我的人)
  ///
  /// [uid] 用戶 ID
  Future<List<String>> getAllExcludedIds(String uid) async {
    try {
      // 並行獲取兩個列表
      final results = await Future.wait([
        getBlockedUserIds(uid),
        getBlockedByUserIds(uid),
      ]);

      // 合併並去重
      final Set<String> excludedIds = {};
      excludedIds.addAll(results[0]);
      excludedIds.addAll(results[1]);

      return excludedIds.toList();
    } catch (e) {
      print('獲取排除名單失敗: $e');
      return [];
    }
  }
}
