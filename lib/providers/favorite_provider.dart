import 'package:flutter/material.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/favorite_service.dart';

class FavoriteProvider with ChangeNotifier {
  final FavoriteService _favoriteService;

  FavoriteProvider({FavoriteService? favoriteService})
      : _favoriteService = favoriteService ?? FavoriteService();

  List<UserModel> _favorites = [];
  final Set<String> _favoriteIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<UserModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 檢查是否已收藏
  bool isFavorite(String targetUserId) {
    return _favoriteIds.contains(targetUserId);
  }

  /// 載入收藏列表
  Future<void> loadFavorites(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      _favorites = await _favoriteService.getFavorites(userId);
      _favoriteIds.clear();
      _favoriteIds.addAll(_favorites.map((user) => user.uid));

      _setLoading(false);
    } catch (e) {
      print('載入收藏失敗: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
    }
  }

  /// 切換收藏狀態
  Future<void> toggleFavorite(String userId, UserModel targetUser) async {
    final targetUserId = targetUser.uid;
    final isCurrentlyFavorite = _favoriteIds.contains(targetUserId);

    try {
      // 樂觀更新
      if (isCurrentlyFavorite) {
        _favoriteIds.remove(targetUserId);
        _favorites.removeWhere((user) => user.uid == targetUserId);
      } else {
        _favoriteIds.add(targetUserId);
        _favorites.insert(0, targetUser); // 加到最前面
      }
      notifyListeners();

      // 執行後台操作
      if (isCurrentlyFavorite) {
        await _favoriteService.removeFavorite(userId, targetUserId);
      } else {
        await _favoriteService.addFavorite(userId, targetUserId);
      }
    } catch (e) {
      // 回滾
      if (isCurrentlyFavorite) {
        _favoriteIds.add(targetUserId);
        _favorites.insert(0, targetUser); // 簡易回滾
      } else {
        _favoriteIds.remove(targetUserId);
        _favorites.removeWhere((user) => user.uid == targetUserId);
      }
      notifyListeners();

      print('切換收藏失敗: $e');
      _errorMessage = '操作失敗，請稍後再試';
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
