import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/favorite_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/utils/image_cache_manager.dart';

class UserDetailScreen extends StatefulWidget {
  final String? userId;
  final UserModel? user;

  const UserDetailScreen({
    super.key,
    this.userId,
    this.user,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isFavorite = false;
  final FavoriteService _favoriteService = FavoriteService();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;

    // Load User Data
    if (widget.user != null) {
      _user = widget.user;
      _isLoading = false;
    } else if (widget.userId != null) {
      try {
        final user = await _firestoreService.getUser(widget.userId!);
        if (mounted) {
          setState(() {
            _user = user;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('無法載入用戶資料: $e')),
          );
        }
      }
    } else {
      // Fallback for dummy data testing if no args provided
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Check Favorite Status
    if (currentUserId != null && _user != null) {
      try {
        final isFav = await _favoriteService.isFavorite(currentUserId, _user!.uid);
        if (mounted) {
          setState(() {
            _isFavorite = isFav;
          });
        }
      } catch (e) {
        print('Error checking favorite status: $e');
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;

    if (currentUserId == null || _user == null) return;

    try {
      if (_isFavorite) {
        await _favoriteService.removeFavorite(currentUserId, _user!.uid);
      } else {
        await _favoriteService.addFavorite(currentUserId, _user!.uid);
      }

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? '已加入收藏' : '已取消收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Use passed user or fallback to dummy if null (for backward compatibility/testing)
    // In production, we should handle null user gracefully
    final user = _user;

    if (user == null && widget.userId != null) {
       return Scaffold(
        appBar: AppBar(title: const Text('錯誤')),
        body: const Center(child: Text('找不到用戶')),
      );
    }

    // If we have a real user, use it. Otherwise use the hardcoded dummy UI (for now)
    // But since I'm refactoring, I should try to use the real user data if available.
    // If not, I'll fallback to the original dummy code structure but maybe wrap it in a condition.

    // Actually, let's just make the UI use `user` if available, or dummy values if not.
    final name = user?.name ?? '陳大明';
    final age = user?.age ?? 30;
    final job = user?.job ?? '軟體工程師';
    final location = user != null ? '${user.city}, ${user.district}' : '台北市, 信義區';
    final budget = user?.budgetRangeText ?? 'NT\$ 500-800';
    final bio = user?.bio ?? '熱愛科技與美食，喜歡嘗試各種新餐廳。週末常去爬山或騎單車。希望能認識志同道合的朋友，一起探索城市中的美味。';
    final matchType = user?.preferredMatchTypeText ?? '異性配對';
    final interests = user?.interests ?? ['科技', '美食', '運動', '旅遊', '攝影'];
    final avatarUrl = user?.avatarUrl;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                   Container(
                    decoration: BoxDecoration(
                      gradient: chinguTheme?.primaryGradient,
                    ),
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            cacheManager: ImageCacheManager().manager,
                            placeholder: (context, url) => Center(child: CircularProgressIndicator(color: Colors.white)),
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 140, color: Colors.white),
                          )
                        : const Center(
                            child: Icon(
                              Icons.person,
                              size: 140,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  // 配對度標籤 (Dummy for now)
                  if (user == null) // Only show if dummy
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: chinguTheme?.successGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (chinguTheme?.success ?? Colors.green).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '95% 配對',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基本資訊
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '$name, $age',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (user == null) // Show active indicator only for dummy or if we had real status
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: chinguTheme?.success ?? Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              job,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Verified Badge (Dummy)
                      if (user == null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.successGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 資訊卡片
                  _buildInfoCard(
                    Icons.location_on_rounded,
                    '位置',
                    location,
                    theme.colorScheme.primary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.payments_rounded,
                    '預算範圍',
                    budget,
                    chinguTheme?.secondary ?? theme.colorScheme.secondary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.favorite_rounded,
                    '配對類型',
                    matchType,
                    chinguTheme?.error ?? theme.colorScheme.error,
                    theme,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 關於我
                  Row(
                    children: [
                      Icon(
                        Icons.info_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '關於我',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
                    ),
                    child: Text(
                      bio,
                      style: TextStyle(
                        fontSize: 15,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.6,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 興趣愛好
                  Row(
                    children: [
                      Icon(
                        Icons.interests_rounded,
                        size: 20,
                        color: chinguTheme?.secondary ?? theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '興趣愛好',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: interests.map((interest) {
                       // Assign random colors or cycle through them based on hash/index if possible
                       // For now, just use Primary color for simplicity
                       return _buildInterestChip(interest, Icons.star, theme.colorScheme.primary);
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 操作按鈕
                  if (user != null)
                  Row(
                    children: [
                      /* Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '略過',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), */
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isFavorite
                                ? null
                                : chinguTheme?.primaryGradient,
                            color: _isFavorite ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _toggleFavorite,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: _isFavorite ? Colors.grey[300] : Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: _isFavorite ? Colors.red : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isFavorite ? '已收藏' : '收藏',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _isFavorite ? Colors.black87 : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  else
                   // Original Dummy Buttons
                   Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '略過',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: chinguTheme?.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  '喜歡',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoCard(IconData icon, String label, String value, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInterestChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
