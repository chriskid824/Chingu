import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/widgets/gradient_header.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  String? _error;
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure context is available for Provider access if needed,
    // though for listen: false it's fine in initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFavorites();
    });
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final favoriteIds = authProvider.userModel?.favoriteIds ?? [];

    if (favoriteIds.isEmpty) {
      if (mounted) {
        setState(() {
          _users = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final users = await _firestoreService.getBatchUsers(favoriteIds);

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onToggleFavorite(String userId) {
    final authProvider = context.read<AuthProvider>();

    // Optimistically remove from local list
    final userIndex = _users.indexWhere((u) => u.uid == userId);
    final user = userIndex != -1 ? _users[userIndex] : null;

    setState(() {
       _users.removeWhere((u) => u.uid == userId);
    });

    authProvider.toggleFavorite(userId).then((_) {
        // Success, do nothing (Consumer handles the global state, but we manage local list for smooth UX)
    }).catchError((e) {
        // If failed, add back
        if (user != null && mounted) {
            setState(() {
                _users.insert(userIndex, user);
            });
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('操作失敗: $e')),
            );
        }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // We listen to AuthProvider only to detect if favoriteIds list was cleared or changed drastically from outside,
    // but for simple toggle, our local state is enough.
    // However, if we navigate to UserDetail and toggle there, we want this list to update when we pop back.
    // The easiest way is to re-fetch or rely on the popped result.
    // But `getBatchUsers` is async.
    // Let's rely on `_loadFavorites` when we know data might be stale, e.g. using Consumer.

    // Actually, `Consumer` rebuilds this widget. But we are storing state in `_users`.
    // If `favoriteIds` in AuthProvider changes, we should ideally sync `_users`.
    // But implementing a full sync diff is complex.
    // Simpler: Just rely on `_loadFavorites` being called on init.
    // And when coming back from Detail screen, we can re-fetch.

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          GradientHeader(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        '我的收藏',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance for back button
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                // If the user has no favorite IDs at all, we can show empty state immediately.
                final favoriteIds = authProvider.userModel?.favoriteIds ?? [];
                if (favoriteIds.isEmpty && !_isLoading) {
                   return _buildEmptyState(theme);
                }

                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_error != null) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text('載入失敗: $_error'),
                              ElevatedButton(
                                  onPressed: _loadFavorites,
                                  child: const Text('重試'),
                              )
                          ]
                      )
                  );
                }

                if (_users.isEmpty) {
                   return _buildEmptyState(theme);
                }

                return RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserListItem(context, user);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              '尚無收藏',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '當您看到感興趣的人時，\n點擊星星圖示即可收藏。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildUserListItem(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.userDetail,
              arguments: user,
            ).then((_) {
              // Reload when coming back to ensure sync
              _loadFavorites();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Hero(
                  tag: 'avatar_${user.uid}',
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    backgroundColor: chinguTheme?.primary?.withOpacity(0.1) ?? Colors.grey[200],
                    child: user.avatarUrl == null
                        ? Icon(Icons.person, color: chinguTheme?.primary)
                        : null,
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (user.subscription == 'premium')
                            Icon(
                              Icons.verified,
                              size: 16,
                              color: chinguTheme?.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.job,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${user.city} ${user.district}',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action
                IconButton(
                  icon: Icon(Icons.star_rounded, color: chinguTheme?.warning ?? Colors.amber),
                  onPressed: () => _onToggleFavorite(user.uid),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
