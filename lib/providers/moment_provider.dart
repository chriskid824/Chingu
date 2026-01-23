import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/moment_service.dart';

class MomentProvider with ChangeNotifier {
  final MomentService _momentService = MomentService();

  List<MomentModel> _moments = [];
  bool _isLoading = false;
  String? _errorMessage;
  // Ignoring pagination implementation for now to focus on like/comment functionality
  // DocumentSnapshot? _lastDocument;
  // bool _hasMore = true;

  List<MomentModel> get moments => _moments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMoments({String? currentUserId, bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMoments = await _momentService.fetchMoments(
        currentUserId: currentUserId,
        limit: 20,
      );

      _moments = newMoments;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String momentId, String userId) async {
    // Optimistic update
    final index = _moments.indexWhere((m) => m.id == momentId);
    if (index != -1) {
      final moment = _moments[index];
      final newIsLiked = !moment.isLiked;
      final newCount = moment.likeCount + (newIsLiked ? 1 : -1);

      _moments[index] = moment.copyWith(
        isLiked: newIsLiked,
        likeCount: newCount,
      );
      notifyListeners();
    }

    try {
      await _momentService.toggleLike(momentId, userId);
    } catch (e) {
      // Revert on failure
      final index = _moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        final moment = _moments[index];
        _moments[index] = moment.copyWith(
          isLiked: !moment.isLiked, // Revert
          likeCount: moment.likeCount + (!moment.isLiked ? 1 : -1), // Revert
        );
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> addComment(String momentId, String userId, String content, String userName, String? userAvatar) async {
    try {
      await _momentService.addComment(momentId, userId, content, userName, userAvatar);

      // Update local count
      final index = _moments.indexWhere((m) => m.id == momentId);
      if (index != -1) {
        _moments[index] = _moments[index].copyWith(
          commentCount: _moments[index].commentCount + 1,
        );
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String momentId) {
    return _momentService.getComments(momentId);
  }
}
