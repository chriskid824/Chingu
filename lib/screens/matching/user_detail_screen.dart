import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/utils/image_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isFavorited = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }

  UserModel? _getUser(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is UserModel) {
      return args;
    }
    return null;
  }

  void _checkFavoriteStatus() {
    final currentUser = context.read<AuthProvider>().userModel;
    final targetUser = _getUser(context);

    if (currentUser != null && targetUser != null) {
      setState(() {
        _isFavorited = currentUser.favoriteUserIds.contains(targetUser.uid);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = context.read<AuthProvider>().userModel;
    final targetUser = _getUser(context);

    if (currentUser == null || targetUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirestoreService().toggleFavorite(currentUser.uid, targetUser.uid);

      // 更新本地狀態
      if (mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
          // 同步更新 AuthProvider
          final authProvider = context.read<AuthProvider>();
          // 這裡雖然 AuthProvider 可能沒有直接更新 favoriteUserIds 的方法，
          // 但我們可以觸發一次 refreshUserData 或者手動更新本地 model
          authProvider.refreshUserData();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorited ? '已加入收藏' : '已取消收藏'),
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = _getUser(context);

    // 如果沒有用戶資料（例如直接從路由訪問但沒帶參數），顯示錯誤或加載中
    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('無法載入用戶資料')),
      );
    }

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
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
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
                    child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary)
                        )
                      : Icon(
                          _isFavorited ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 24,
                          color: _isFavorited ? (chinguTheme?.warning ?? Colors.amber) : theme.colorScheme.onSurface,
                        ),
                  ),
                  onPressed: _isLoading ? null : _toggleFavorite,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: user.avatarUrl!,
                          fit: BoxFit.cover,
                          cacheManager: ImageCacheManager().manager,
                          placeholder: (context, url) => Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: chinguTheme?.primaryGradient,
                            ),
                            child: const Icon(Icons.person, size: 140, color: Colors.white),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: chinguTheme?.primaryGradient,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person,
                              size: 140,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.4),
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
                                  '${user.name}, ${user.age}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (user.subscription == 'premium')
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
                              user.job,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.subscription == 'premium')
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
                    '${user.city}, ${user.district}',
                    theme.colorScheme.primary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.payments_rounded,
                    '預算範圍',
                    user.budgetRangeText,
                    chinguTheme?.secondary ?? theme.colorScheme.secondary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.favorite_rounded,
                    '配對類型',
                    user.preferredMatchTypeText,
                    chinguTheme?.error ?? theme.colorScheme.error,
                    theme,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 關於我
                  if (user.bio != null && user.bio!.isNotEmpty) ...[
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
                        user.bio!,
                        style: TextStyle(
                          fontSize: 15,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
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
                    children: user.interests.map((interest) {
                      // 簡單的顏色循環分配
                      final colors = [
                        theme.colorScheme.primary,
                        chinguTheme?.error ?? Colors.red,
                        chinguTheme?.success ?? Colors.green,
                        chinguTheme?.warning ?? Colors.amber,
                        chinguTheme?.secondary ?? Colors.purple,
                      ];
                      final color = colors[user.interests.indexOf(interest) % colors.length];

                      return _buildInterestChip(interest, Icons.star, color);
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 操作按鈕 (目前僅保留返回和收藏，原始的 "Skip/Like" 在這裡可能不需要，除非是在配對流程中)
                  // 如果是從配對頁面點進來，這些按鈕才有意義。如果是從收藏頁面進來，則不一定需要。
                  // 這裡我們只顯示一個 "發送訊息" 或類似的按鈕，如果他們已經匹配。
                  // 但根據需求，我們只關注收藏功能。
                  // 這裡我們可以放一個大的 "加入收藏" 按鈕，如果上面 AppBar 的不明顯。
                  // 或者，如果這是個人詳情頁，通常會有 "發起聊天" 的按鈕。

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFavorite,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _isFavorited
                            ? theme.cardColor
                            : theme.colorScheme.primary,
                        foregroundColor: _isFavorited
                            ? theme.colorScheme.onSurface
                            : Colors.white,
                        side: _isFavorited
                            ? BorderSide(color: theme.dividerColor)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isFavorited ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: _isFavorited ? (chinguTheme?.warning ?? Colors.amber) : Colors.white
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFavorited ? '已收藏' : '加入收藏',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
