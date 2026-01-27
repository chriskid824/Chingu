import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_header.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/utils/image_cache_manager.dart';
import 'package:chingu/widgets/animated_counter.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('ProfileDetailScreen building...');
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          
          if (user == null) {
            if (authProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      '無法載入個人資料',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.errorMessage ?? '未知錯誤',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => authProvider.refreshUserData(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重試'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        await authProvider.signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            AppRoutes.login,
                            (route) => false,
                          );
                        }
                      },
                      child: const Text('強制登出'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // 頂部個人資料卡片
                GradientHeader(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, color: Colors.white),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.profilePreview),
                              tooltip: '預覽',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: user.avatarUrl != null
                                ? CircleAvatar(
                                    backgroundImage: CachedNetworkImageProvider(
                                      user.avatarUrl!,
                                      cacheManager: ImageCacheManager().manager,
                                    ),
                                    radius: 50,
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 60,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${user.name}, ${user.age}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                user.job,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 統計資料
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(context, '配對', user.totalMatches),
                            _buildVerticalDivider(),
                            _buildStatItem(context, '聚餐', user.totalDinners),
                            _buildVerticalDivider(),
                            _buildStatItem(context, '評分', user.averageRating, isRating: true),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  '我的活動',
                                  Icons.event_note_rounded,
                                  () => Navigator.pushNamed(context, AppRoutes.eventHistory),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  '開發者工具',
                                  Icons.bug_report_rounded,
                                  () => Navigator.pushNamed(context, AppRoutes.debug),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                
                // 詳細資料
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, '關於我'),
                      const SizedBox(height: 12),
                      Text(
                        user.bio ?? '這個人很懶，什麼都沒寫...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle(context, '興趣'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: user.interests.map((interest) {
                          return _buildInterestChip(context, interest, Icons.star_border_rounded);
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle(context, '基本資料'),
                      const SizedBox(height: 12),
                      _buildInfoRow(context, Icons.location_on_outlined, '居住地', '${user.city} ${user.district}'),
                      _buildInfoRow(context, Icons.person_outline, '性別', user.gender == 'male' ? '男' : '女'),
                      _buildInfoRow(context, Icons.monetization_on_outlined, '預算', user.budgetRangeText),
                      
                      const SizedBox(height: 40),
                      
                      // 登出按鈕
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await context.read<AuthProvider>().signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                            }
                          },
                          icon: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
                          label: Text('登出', style: TextStyle(color: theme.colorScheme.error)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                            side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInterestChip(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall,
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, num value, {bool isRating = false}) {
    return Column(
      children: [
        AnimatedCounter(
          value: value,
          decimalPlaces: isRating ? 1 : 0,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }
}
