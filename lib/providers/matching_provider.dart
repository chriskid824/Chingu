import 'package:flutter/material.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:chingu/services/crash_reporting_service.dart';

class MatchingProvider with ChangeNotifier {
  final MatchingService _matchingService = MatchingService();

  List<UserModel> _candidates = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 載入候選人
  Future<void> loadCandidates(UserModel currentUser) async {
    try {
      if (currentUser.city.isEmpty) {
        _errorMessage = '請先完善個人資料中的城市資訊';
        notifyListeners();
        return;
      }

      _setLoading(true);
      _errorMessage = null;

      print('=== 開始載入候選人 ===');
      print('當前用戶: ${currentUser.name}');
      print('城市: ${currentUser.city}');
      print('年齡: ${currentUser.age}');
      print('性別偏好: ${currentUser.preferredMatchType}');
      print('年齡範圍: ${currentUser.minAge}-${currentUser.maxAge}');

      // 設定 10 秒超時，避免無限轉圈
      final matches = await _matchingService.getMatches(currentUser).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('連線逾時，請檢查網路或稍後再試');
        },
      );
      
      print('從資料庫獲得 ${matches.length} 個候選人');
      
      // 將 Map 轉換回 UserModel 列表
      _candidates = matches.map((m) => m['user'] as UserModel).toList();

      print('最終候選人數量: ${_candidates.length}');
      if (_candidates.isNotEmpty) {
        print('第一個候選人: ${_candidates.first.name}');
      }

      _setLoading(false);
    } catch (e, s) {
      CrashReportingService().recordError(e, s, reason: 'Load Candidates Failed');
      print('載入候選人錯誤: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      // notifyListeners 已經在 _setLoading 中調用，但如果 _isLoading 沒變（原本就是 false），則需要手動通知
      notifyListeners();
    }
  }

  /// 處理喜歡/不喜歡
  /// 如果配對成功，返回配對資訊 { 'chatRoomId': String, 'partner': UserModel }
  Future<Map<String, dynamic>?> swipe(String userId, String targetUserId, bool isLike) async {
    try {
      // 樂觀更新 UI：先從列表中移除
      _candidates.removeWhere((user) => user.uid == targetUserId);
      notifyListeners();

      // 後台執行記錄
      final result = await _matchingService.recordSwipe(userId, targetUserId, isLike);
      
      if (result['isMatch'] == true) {
        return {
          'chatRoomId': result['chatRoomId'],
          'partner': result['partner'],
        };
      }
      
      // 如果列表空了，嘗試重新加載
      if (_candidates.isEmpty) {
        // 這裡需要傳入 currentUser，但在 swipe 方法中通常不方便獲取完整的 UserModel
        // 實際應用中可以緩存 currentUser 或者通過 AuthProvider 獲取
        // 暫時不做自動重新加載，或者在 UI 層處理
      }
      
      return null;
    } catch (e, s) {
      CrashReportingService().recordError(e, s, reason: 'Swipe Action Failed');
      // 如果失敗，可能需要提示用戶或回滾（這裡簡化處理）
      print('滑動操作失敗: $e');
      return null;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 重置配對歷史 (測試用)
  Future<void> resetHistory(UserModel currentUser) async {
    try {
      _setLoading(true);
      await _matchingService.clearSwipeHistory(currentUser.uid);
      await loadCandidates(currentUser);
    } catch (e, s) {
      CrashReportingService().recordError(e, s, reason: 'Reset History Failed');
      _errorMessage = '重置失敗: $e';
      _setLoading(false);
    }
  }
}
