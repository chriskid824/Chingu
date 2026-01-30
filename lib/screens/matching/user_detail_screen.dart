import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/favorite_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserDetailScreen extends StatefulWidget {
  final String? userId;
  final UserModel? userModel;

  const UserDetailScreen({super.key, this.userId, this.userModel});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  UserModel? _user;
  bool _isLoading = true;
  bool _isFavorite = false;
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.userModel != null) {
      if (mounted) {
        setState(() {
          _user = widget.userModel;
          _isLoading = false;
        });
        _checkFavoriteStatus();
      }
    } else {
      // Defer argument reading to after build frame if needed, or just do it here if possible.
      // Safest in initState is to use postFrameCallback for inherited widgets, but arguments are on Route.
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final args = ModalRoute.of(context)?.settings.arguments;

        if (args is Map<String, dynamic>) {
          if (args['userModel'] is UserModel) {
            if (mounted) {
              setState(() {
                _user = args['userModel'];
                _isLoading = false;
              });
              _checkFavoriteStatus();
            }
          } else if (args['userId'] is String) {
            await _fetchUser(args['userId']);
          } else {
            // No valid args found
            if (mounted) setState(() => _isLoading = false);
          }
        } else if (widget.userId != null) {
          await _fetchUser(widget.userId!);
        } else {
          // No args, no widget prop
          if (mounted) setState(() => _isLoading = false);
        }
      });
    }
  }

  Future<void> _fetchUser(String uid) async {
    try {
      final user = await FirestoreService().getUser(uid);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
        _checkFavoriteStatus();
      }
    } catch (e) {
      print('Error fetching user: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final currentUser = context.read<AuthProvider>().userModel;
    final targetUser = _user; // Use the loaded user

    if (currentUser != null && targetUser != null) {
       final isFav = await _favoriteService.isFavorite(currentUser.uid, targetUser.uid);
       if (mounted) {
         setState(() {
           _isFavorite = isFav;
         });
       }
    }
  }

  Future<void> _toggleFavorite() async {
    final currentUser = context.read<AuthProvider>().userModel;
    final targetUser = _user;

    if (currentUser == null || targetUser == null) return;

    // Prevent toggling for dummy user if desired, but for now let's allow it if it has an ID
    if (targetUser.uid == 'dummy') return;

    try {
      final isFav = await _favoriteService.toggleFavorite(currentUser.uid, targetUser.uid);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFav ? '已加入收藏' : '已移除收藏'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失敗: $e')),
      );
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

    // Fallback Dummy User
    final user = _user ?? UserModel(
      uid: 'dummy',
      name: '陳大明',
      email: 'dummy@example.com',
      age: 30,
      gender: 'male',
      job: '軟體工程師',
      interests: ['科技', '美食', '運動', '旅遊', '攝影'],
      country: 'Taiwan',
      city: '台北市',
      district: '信義區',
      bio: '熱愛科技與美食，喜歡嘗試各種新餐廳。週末常去爬山或騎單車。希望能認識志同道合的朋友，一起探索城市中的美味。',
      preferredMatchType: 'opposite',
      minAge: 18,
      maxAge: 40,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );

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
                  color: theme.cardColor.withOpacity(0.8),
                  shape: BoxShape.circle,
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
              // Favorite Button
              if (user.uid != 'dummy') // Only show for real users
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.cardColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 24,
                      color: _isFavorite ? (chinguTheme?.warning ?? Colors.amber) : theme.colorScheme.onSurface,
                    ),
                  ),
                  onPressed: _toggleFavorite,
                ),
              const SizedBox(width: 16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  user.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.person),
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
                  // 配對度標籤 (保持原本樣式)
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
                                  '${user.name}, ${user.age}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                      return _buildInterestChip(interest, Icons.star, theme.colorScheme.primary);
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // 操作按鈕
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                             Navigator.pop(context);
                          },
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
                            onPressed: () {
                               // Existing Like logic (Swipe Right)
                               // For now, maybe just show a snackbar or close
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('已送出喜歡')),
                               );
                            },
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
