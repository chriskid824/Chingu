import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
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

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
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
                            // 設定按鈕
                            IconButton(
                              icon: const Icon(Icons.settings_outlined, color: Colors.white),
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
                              tooltip: '設定',
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 編輯資料按鈕
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.editProfile),
                                  tooltip: '編輯資料',
                                ),
                                // 預覽按鈕
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, color: Colors.white),
                                  onPressed: () => Navigator.pushNamed(context, AppRoutes.profilePreview),
                                  tooltip: '預覽',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
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
                                    color: AppColorsMinimal.primary,
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
                            color: Colors.white.withValues(alpha: 0.2),
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
                        // Debug Button — 僅開發模式顯示
                        if (kDebugMode)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, AppRoutes.debug);
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bug_report_rounded, size: 16, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text(
                                      '開發者工具',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
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
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: AppColorsMinimal.textSecondary,
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
                      _buildInfoRow(context, Icons.person_outline, '性別', user.genderText),
                      
                      const SizedBox(height: 40),
                      
                      // 登出按鈕
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            // 只 signOut，AuthGate 會自動導到 LoginScreen
                            await context.read<AuthProvider>().signOut();
                          },
                          icon: Icon(Icons.logout_rounded, color: AppColorsMinimal.error),
                          label: Text('登出', style: TextStyle(color: AppColorsMinimal.error)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColorsMinimal.error,
                            side: BorderSide(color: AppColorsMinimal.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColorsMinimal.textPrimary,
      ),
    );
  }

  Widget _buildInterestChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColorsMinimal.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColorsMinimal.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorsMinimal.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColorsMinimal.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColorsMinimal.textTertiary),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColorsMinimal.textPrimary,
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
            color: Colors.white.withValues(alpha: 0.8),
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
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}
