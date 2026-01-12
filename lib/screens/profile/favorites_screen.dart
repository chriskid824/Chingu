import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/widgets/app_icon_button.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  List<UserModel> _favoriteUsers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteIds = authProvider.userModel?.favoriteIds ?? [];

    if (favoriteIds.isEmpty) {
      setState(() {
        _favoriteUsers = [];
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final users = await _firestoreService.getBatchUsers(favoriteIds);

      if (mounted) {
        setState(() {
          _favoriteUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '載入收藏列表失敗: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // 監聽 AuthProvider 的變化，如果有取消收藏的操作，即時更新列表
    // 注意：這是一個簡單的實現，如果從其他地方更新了收藏，這裡需要重新拉取
    // 更好的做法可能是使用 Stream 或在 AuthProvider 中管理 favoriteUsers 列表

    // 這裡我們簡單地過濾掉不在 favoriteIds 中的用戶
    final currentFavoriteIds = authProvider.userModel?.favoriteIds ?? [];
    final displayUsers = _favoriteUsers.where((u) => currentFavoriteIds.contains(u.uid)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        leading: AppIconButton(
          icon: Icons.arrow_back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(theme, displayUsers),
    );
  }

  Widget _buildBody(ThemeData theme, List<UserModel> users) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: theme.colorScheme.primary,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFavorites,
              child: const Text('重試'),
            ),
          ],
        ),
      );
    }

    if (users.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.favorite_border,
        title: '尚無收藏',
        message: '當您在瀏覽時看到感興趣的用戶，\n點擊愛心圖示即可加入收藏。',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final user = users[index];
        return _buildUserCard(context, theme, user);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, ThemeData theme, UserModel user) {
    final chinguTheme = theme.extension<ChinguTheme>();

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.userDetail,
          arguments: user,
        ).then((_) {
          // 返回後刷新，以防在詳情頁取消了收藏
           _loadFavorites();
        });
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // 頭像
            Hero(
              tag: 'avatar_${user.uid}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  image: DecorationImage(
                    image: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : const AssetImage('assets/images/placeholder_avatar.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 資料
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          user.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${user.age}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.job,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${user.city}, ${user.district}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 操作按鈕
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.favorite),
                color: const Color(0xFFFF5252), // 紅色愛心
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  try {
                    await authProvider.toggleFavorite(user.uid);
                    // UI 會自動通過 Consumer 更新，因為我們過濾了 favoriteIds
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('操作失敗: $e')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
