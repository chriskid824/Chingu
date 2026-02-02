import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;

    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '用戶未登入';
        });
      }
      return;
    }

    if (currentUser.favoriteIds.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _favorites = [];
        });
      }
      return;
    }

    try {
      final users = await _firestoreService.getBatchUsers(currentUser.favoriteIds);
      if (mounted) {
        setState(() {
          _favorites = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '載入收藏失敗: $e';
        });
      }
    }
  }

  Future<void> _removeFavorite(String targetUserId) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    try {
      // Optimistic remove
      final removedUserIndex = _favorites.indexWhere((u) => u.uid == targetUserId);
      if (removedUserIndex == -1) return;

      final removedUser = _favorites[removedUserIndex];

      setState(() {
        _favorites.removeAt(removedUserIndex);
      });

      await _firestoreService.removeFavorite(currentUser.uid, targetUserId);
      await authProvider.refreshUserData(); // Refresh provider to sync IDs

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已從收藏中移除 ${removedUser.name}'),
            action: SnackBarAction(
              label: '復原',
              onPressed: () {
                _addFavoriteBack(currentUser.uid, removedUser);
              },
            ),
          ),
        );
      }
    } catch (e) {
       // Restore on error
       _loadFavorites();
       if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('移除失敗: $e')),
          );
       }
    }
  }

  Future<void> _addFavoriteBack(String currentUserId, UserModel user) async {
    await _firestoreService.addFavorite(currentUserId, user.uid);
    await context.read<AuthProvider>().refreshUserData();
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '我的收藏',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)))
              : _favorites.isEmpty
                  ? _buildEmptyState(context, theme)
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favorites.length,
                        itemBuilder: (context, index) {
                          final user = _favorites[index];
                          return _buildUserCard(context, user, theme, chinguTheme);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            '暫無收藏',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '看到感興趣的對象，點擊收藏按鈕加入這裡',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, UserModel user, ThemeData theme, ChinguTheme? chinguTheme) {
    return Dismissible(
      key: Key(user.uid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: chinguTheme?.error ?? Colors.red,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 32),
      ),
      onDismissed: (_) => _removeFavorite(user.uid),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shadowColor: theme.shadowColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.userDetail,
              arguments: user,
            ).then((_) {
              // Reload when returning (in case favorite status changed in detail screen)
              _loadFavorites();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: ClipOval(
                    child: user.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: user.avatarUrl!,
                            fit: BoxFit.cover,
                            cacheManager: ImageCacheManager().manager,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceVariant,
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${user.name}, ${user.age}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (user.subscription == 'premium')
                            Icon(Icons.verified_rounded, size: 16, color: chinguTheme?.success ?? Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.job.isNotEmpty ? user.job : '未填寫職業',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${user.city} ${user.district}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
