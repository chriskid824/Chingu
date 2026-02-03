import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/favorite_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  bool _isLoading = true;
  List<UserModel> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final favorites = await _favoriteService.getFavorites(userId);
      if (mounted) {
        setState(() {
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法載入收藏列表: $e')),
        );
      }
    }
  }

  Future<void> _removeFavorite(UserModel user) async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    try {
      await _favoriteService.removeFavorite(userId, user.uid);
      if (mounted) {
        setState(() {
          _favorites.removeWhere((u) => u.uid == user.uid);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已移除收藏')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('移除失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? _buildEmptyState(theme)
              : ListView.builder(
                  itemCount: _favorites.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final user = _favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundImage: user.avatarUrl != null
                              ? CachedNetworkImageProvider(
                                  user.avatarUrl!,
                                  cacheManager: ImageCacheManager().manager,
                                )
                              : null,
                          child: user.avatarUrl == null
                              ? Icon(Icons.person, color: theme.colorScheme.primary)
                              : null,
                        ),
                        title: Text(
                          '${user.name}, ${user.age}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${user.job} • ${user.city}'),
                        trailing: IconButton(
                          icon: Icon(Icons.favorite, color: theme.colorScheme.primary),
                          onPressed: () => _removeFavorite(user),
                        ),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.userDetail,
                            arguments: {'user': user},
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            '尚無收藏',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
