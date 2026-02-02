import 'dart:io';
import 'package:flutter/material.dart';
import 'package:chingu/models/moment_model.dart';
import 'package:chingu/services/moment_service.dart';

class MomentProvider with ChangeNotifier {
  final MomentService _momentService;

  MomentProvider({MomentService? momentService})
      : _momentService = momentService ?? MomentService();

  List<MomentModel> _moments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<MomentModel> get moments => _moments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Fetch moments for a specific user
  Future<void> fetchUserMoments(String userId, {String? currentUserId}) async {
    try {
      _setLoading(true);
      _errorMessage = null;
      _moments = await _momentService.getMoments(
        userId: userId,
        currentUserId: currentUserId,
      );
      _setLoading(false);
    } catch (e) {
      debugPrint('Failed to fetch moments: $e');
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  /// Create a new moment
  Future<bool> createMoment({
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
    File? imageFile,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _momentService.createMoment(
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: content,
        imageFile: imageFile,
      );

      // Refresh list
      await fetchUserMoments(userId, currentUserId: userId);

      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Failed to create moment: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Toggle like
  Future<void> toggleLike(String momentId, String userId) async {
    // Optimistic update
    final index = _moments.indexWhere((m) => m.id == momentId);
    if (index != -1) {
      final moment = _moments[index];
      final newIsLiked = !moment.isLiked;
      final newLikeCount = moment.likeCount + (newIsLiked ? 1 : -1);

      _moments[index] = moment.copyWith(
        isLiked: newIsLiked,
        likeCount: newLikeCount,
      );
      notifyListeners();

      try {
        final result = await _momentService.toggleLike(momentId, userId);
        // Correct state if mismatch (optional, but good practice)
        if (result != newIsLiked) {
           _moments[index] = moment.copyWith(
            isLiked: result,
            likeCount: moment.likeCount + (result ? 1 : -1), // roughly correct
          );
          notifyListeners();
        }
      } catch (e) {
        // Revert on failure
        _moments[index] = moment;
        notifyListeners();
        debugPrint('Failed to toggle like: $e');
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
