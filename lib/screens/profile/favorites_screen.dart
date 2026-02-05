import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/favorite_provider.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userModel?.uid;
      if (userId != null) {
        context.read<FavoriteProvider>().loadFavorites(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final favoriteProvider = context.watch<FavoriteProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '我的收藏',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: favoriteProvider.isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : favoriteProvider.favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        '還沒有收藏的用戶',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favoriteProvider.favorites.length,
                  itemBuilder: (context, index) {
                    final user = favoriteProvider.favorites[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.userDetail,
                            arguments: user,
                          );
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
                                  color: Colors.grey[200],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: user.avatarUrl != null
                                    ? CachedNetworkImage(
                                        imageUrl: user.avatarUrl!,
                                        fit: BoxFit.cover,
                                        cacheManager: ImageCacheManager().manager,
                                        errorWidget: (context, url, error) => Icon(Icons.person, color: Colors.grey[400]),
                                      )
                                    : Icon(Icons.person, size: 40, color: Colors.grey[400]),
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (user.subscription == 'premium') ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, size: 16, color: Colors.blue),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${user.job} • ${user.city}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Arrow
                              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
