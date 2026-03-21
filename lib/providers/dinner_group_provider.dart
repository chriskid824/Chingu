import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/dinner_group_model.dart';

/// 管理用戶的晚餐群組資料
class DinnerGroupProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<DinnerGroupModel> _myGroups = [];
  List<DinnerGroupModel> get myGroups => _myGroups;

  DinnerGroupModel? _currentGroup;
  DinnerGroupModel? get currentGroup => _currentGroup;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 取得用戶參與的所有群組（依建立時間倒序）
  Future<void> fetchMyGroups(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('dinnerGroups')
          .where('participantIds', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      _myGroups = snapshot.docs
          .map((doc) => DinnerGroupModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('[DinnerGroupProvider] fetchMyGroups error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 監聽特定群組的即時更新
  Stream<DinnerGroupModel?> watchGroup(String groupId) {
    return _firestore
        .collection('dinnerGroups')
        .doc(groupId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final group = DinnerGroupModel.fromFirestore(doc);
      _currentGroup = group;
      notifyListeners();
      return group;
    });
  }

  /// 確認出席
  Future<void> confirmAttendance(String groupId, String userId) async {
    try {
      await _firestore.collection('dinnerGroups').doc(groupId).update({
        'attendanceConfirmed.$userId': true,
      });

      // 更新本地狀態
      if (_currentGroup != null && _currentGroup!.id == groupId) {
        final updated = Map<String, bool>.from(_currentGroup!.attendanceConfirmed);
        updated[userId] = true;
        _currentGroup = _currentGroup!.copyWith(attendanceConfirmed: updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DinnerGroupProvider] confirmAttendance error: $e');
    }
  }

  /// 取得當前活動中的群組（非 completed）
  DinnerGroupModel? get activeGroup {
    try {
      return _myGroups.firstWhere(
        (g) => g.status != 'completed',
      );
    } catch (_) {
      return null;
    }
  }
}
