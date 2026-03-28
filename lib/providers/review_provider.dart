import 'package:flutter/material.dart';

import 'package:chingu/services/review_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';

/// 評價 Provider — 管理晚餐後互評流程狀態
class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _pendingGroups = [];
  List<UserModel> _pendingReviewees = [];
  Map<String, bool?> _reviewChoices = {}; // revieweeId -> wantToMeetAgain
  List<String> _newChatRoomIds = []; // mutual match 產生的聊天室

  // P2 漸進式學習
  int? _experienceRating; // 1-5
  List<String> _experienceHighlights = [];
  String? _preferenceForNext;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get pendingGroups => _pendingGroups;
  List<UserModel> get pendingReviewees => _pendingReviewees;
  Map<String, bool?> get reviewChoices => _reviewChoices;
  List<String> get newChatRoomIds => _newChatRoomIds;
  int? get experienceRating => _experienceRating;
  List<String> get experienceHighlights => _experienceHighlights;
  String? get preferenceForNext => _preferenceForNext;
  bool get hasPendingReviews => _pendingGroups.isNotEmpty;
  bool get allReviewsCompleted =>
      _pendingReviewees.isNotEmpty &&
      _reviewChoices.length == _pendingReviewees.length &&
      _reviewChoices.values.every((v) => v != null);

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
    _newChatRoomIds = [];
    notifyListeners();

    try {
      final pendingIds = List<String>.from(group['pendingReviewees'] ?? []);
      debugPrint('📋 待評價成員 IDs: $pendingIds (共 ${pendingIds.length} 人)');
      final users = <UserModel>[];

      for (final uid in pendingIds) {
        final user = await _firestoreService.getUser(uid);
        if (user != null) {
          users.add(user);
          debugPrint('  ✓ 載入用戶: ${user.name} ($uid)');
        } else {
          // Fallback: 建立基本用戶讓畫面仍可操作
          debugPrint('  ⚠ 找不到用戶 $uid，使用 fallback');
          users.add(UserModel(
            uid: uid,
            email: '',
            name: '用戶 ${users.length + 1}',
            age: 0,
            gender: '',
            city: '',
            district: '',
            country: '',
            job: '—',
            interests: const [],
            diningPreference: 'any',
            minAge: 18,
            maxAge: 60,
            budgetRange: 1,
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          ));
        }
      }

      _pendingReviewees = users;
      debugPrint('✓ 已載入 ${users.length} 位待評價成員');
      notifyListeners();
    } catch (e) {
      _error = '載入成員資料失敗: $e';
      debugPrint('❌ loadRevieweesForGroup 失敗: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 設定對某人的評價選擇
  void setReviewChoice(String revieweeId, bool wantToMeetAgain) {
    _reviewChoices[revieweeId] = wantToMeetAgain;
    notifyListeners();
  }

  /// 設定體驗評分
  void setExperienceRating(int rating) {
    _experienceRating = rating;
    notifyListeners();
  }

  /// 切換體驗亮點
  void toggleHighlight(String highlight) {
    if (_experienceHighlights.contains(highlight)) {
      _experienceHighlights.remove(highlight);
    } else {
      _experienceHighlights.add(highlight);
    }
    notifyListeners();
  }

  /// 設定下次偏好
  void setPreferenceForNext(String? pref) {
    _preferenceForNext = pref;
    notifyListeners();
  }

  /// 提交所有評價
  Future<void> submitAllReviews({
    required String reviewerId,
    required String groupId,
    required String eventId,
  }) async {
    _isLoading = true;
    _error = null;
    _newChatRoomIds = [];
    notifyListeners();

    try {
      for (final entry in _reviewChoices.entries) {
        final chatRoomId = await _reviewService.submitReview(
          reviewerId: reviewerId,
          revieweeId: entry.key,
          groupId: groupId,
          eventId: eventId,
          wantToMeetAgain: entry.value ?? false,
          experienceRating: _experienceRating,
          experienceHighlights: _experienceHighlights,
          preferenceForNext: _preferenceForNext,
        );

        if (chatRoomId != null) {
          _newChatRoomIds.add(chatRoomId);
        }
      }

      notifyListeners();
    } catch (e) {
      _error = '提交評價失敗: $e';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 重設狀態
  void reset() {
    _pendingGroups = [];
    _pendingReviewees = [];
    _reviewChoices = {};
    _newChatRoomIds = [];
    _experienceRating = null;
    _experienceHighlights = [];
    _preferenceForNext = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
