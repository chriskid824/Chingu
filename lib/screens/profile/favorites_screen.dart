import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('我的收藏'),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final favorites = authProvider.userModel?.favorites ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 80,
                    color: theme.disabledColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '還沒有收藏的用戶',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '去探索頁面看看吧！',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return FutureBuilder<List<UserModel>>(
            future: FirestoreService().getBatchUsers(favorites),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('載入失敗: ${snapshot.error}'),
                );
              }

              final users = snapshot.data ?? [];

              if (users.isEmpty) {
                return const Center(child: Text('找不到收藏的用戶資料'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _buildUserCard(context, user, theme, chinguTheme);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    UserModel user,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            AppRoutes.userDetail,
            arguments: {'user': user},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.surfaceVariant,
                ),
                child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          cacheManager: ImageCacheManager().manager,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          errorWidget: (context, url, error) =>
                              Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    : Icon(Icons.person, size: 40, color: theme.colorScheme.onSurfaceVariant),
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
                        if (user.gender == 'female')
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.female, size: 16, color: Colors.pink[300]),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.male, size: 16, color: Colors.blue[300]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.job,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
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
    );
  }
}
