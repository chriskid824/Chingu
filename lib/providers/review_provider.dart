import 'package:flutter/material.dart';

import 'package:chingu/services/review_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';

/// 評價 Provider — 管理晚餐後雙盲 👍/👎 互評流程狀態
class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _pendingGroups = [];
  List<UserModel> _pendingReviewees = [];
  Map<String, String> _reviewChoices = {}; // revieweeId -> 'like' | 'dislike'

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get pendingGroups => _pendingGroups;
  List<UserModel> get pendingReviewees => _pendingReviewees;
  Map<String, String> get reviewChoices => _reviewChoices;
  bool get hasPendingReviews => _pendingGroups.isNotEmpty;
  bool get allReviewsCompleted =>
      _pendingReviewees.isNotEmpty &&
      _reviewChoices.isNotEmpty &&
      _reviewChoices.length == _pendingReviewees.length;

  /// 載入待評價群組
  Future<void> loadPendingReviews(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingGroups =
          await _reviewService.getPendingReviewGroups(userId);
      notifyListeners();
    } catch (e) {
      _error = '載入待評價資料失敗: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入某群組待評價的成員資料
  Future<void> loadRevieweesForGroup(Map<String, dynamic> group) async {
    _isLoading = true;
    _error = null;
    _reviewChoices = {};
    _pendingReviewees = [];
    notifyListeners();

    try {
      final pendingIds = List<String>.from(group['pendingReviewees'] ?? []);
      debugPrint('待評價成員 IDs: $pendingIds (共 ${pendingIds.length} 人)');
      final users = <UserModel>[];

      for (final uid in pendingIds) {
        try {
          final user = await _firestoreService.getUser(uid).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw Exception('Timeout'),
          );
          if (user != null) {
            users.add(user);
          } else {
            users.add(_fallbackUser(uid, users.length));
          }
        } catch (e) {
          debugPrint('載入用戶 $uid 失敗 ($e)，使用 fallback');
          users.add(_fallbackUser(uid, users.length));
        }
      }

      _pendingReviewees = users;
      notifyListeners();
    } catch (e) {
      _error = '載入成員資料失敗: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 設定對某人的評價：👍 = 'like'，👎 = 'dislike'
  void setReviewChoice(String revieweeId, String result) {
    _reviewChoices[revieweeId] = result;
    notifyListeners();
  }

  /// 提交所有評價（每筆獨立 try-catch，一筆失敗不影響其他）
  ///
  /// 回傳是否全部成功。失敗時保留 _reviewChoices 讓用戶可以重試,
  /// 只有全部成功才清空(Match 結算與聊天室建立由 Cloud Function 處理)。
  Future<bool> submitAllReviews({
    required String reviewerId,
    required String groupId,
    required String eventId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    int successCount = 0;
    int failCount = 0;
    bool expired = false;

    // 複製一份避免遍歷時修改
    final choices = Map<String, String>.from(_reviewChoices);
    final succeeded = <String>[];

    for (final entry in choices.entries) {
      try {
        await _reviewService.submitReview(
          reviewerId: reviewerId,
          revieweeId: entry.key,
          groupId: groupId,
          eventId: eventId,
          result: entry.value,
        );
        succeeded.add(entry.key);
        successCount++;
      } on ReviewExpiredException {
        expired = true;
        failCount++;
      } catch (e) {
        debugPrint('評價 ${entry.key} 失敗: $e');
        failCount++;
      }
    }

    if (failCount == 0) {
      // 全部成功才清空(防止重複進入)
      _pendingReviewees = [];
      _reviewChoices = {};
    } else {
      // 已成功的從選擇中移除,保留失敗的供重試
      for (final id in succeeded) {
        _reviewChoices.remove(id);
      }
      if (expired) {
        _error = '評價時間已截止，無法再提交';
        _pendingReviewees = [];
        _reviewChoices = {};
      } else if (successCount == 0) {
        _error = '提交評價失敗，請檢查網路後重試';
      } else {
        _error = '部分評價提交失敗（$successCount 成功，$failCount 失敗），請重試';
      }
    }

    _isLoading = false;
    notifyListeners();
    return failCount == 0;
  }

  /// 重設狀態
  void reset() {
    _pendingGroups = [];
    _pendingReviewees = [];
    _reviewChoices = {};
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  UserModel _fallbackUser(String uid, int index) {
    return UserModel(
      uid: uid,
      email: '',
      name: '飯友 ${index + 1}',
      age: -1, // -1 表示未知，UI 端不顯示
      gender: '',
      city: '',
      district: '',
      country: '',
      job: '資料載入中',
      interests: const [],
      diningPreference: 'any',
      minAge: 18,
      maxAge: 60,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }
}
