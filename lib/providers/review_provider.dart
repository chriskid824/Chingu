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
  List<String> _newChatRoomIds = []; // mutual match 產生的聊天室

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get pendingGroups => _pendingGroups;
  List<UserModel> get pendingReviewees => _pendingReviewees;
  Map<String, String> get reviewChoices => _reviewChoices;
  List<String> get newChatRoomIds => _newChatRoomIds;
  bool get hasPendingReviews => _pendingGroups.isNotEmpty;
  bool get allReviewsCompleted =>
      _pendingReviewees.isNotEmpty &&
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
    _newChatRoomIds = [];
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
          result: entry.value,
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
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  UserModel _fallbackUser(String uid, int index) {
    return UserModel(
      uid: uid,
      email: '',
      name: '飯友 ${index + 1}',
      age: 0,
      gender: '',
      city: '',
      district: '',
      country: '',
      job: '',
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
