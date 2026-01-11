import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Retrieve user from arguments
    final user = ModalRoute.of(context)?.settings.arguments as UserModel?;

    // Fallback if no user passed (for development/testing)
    final displayUser = user ?? UserModel(
      uid: 'mock_uid',
      name: '預覽用戶',
      email: 'test@example.com',
      age: 25,
      gender: 'male',
      job: '尚未填寫',
      interests: ['科技', '美食'],
      country: 'TW',
      city: '台北市',
      district: '信義區',
      bio: '這是一個預覽用戶資料。請確保傳入正確的 UserModel。',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 99,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      averageRating: 0.0,
      ratingCount: 0,
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
                  if (displayUser.avatarUrl != null)
                    CachedNetworkImage(
                      imageUrl: displayUser.avatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.person,
                          size: 140,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Container(
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

                  // Rating Badge (Only show if there are ratings)
                  if (displayUser.ratingCount > 0)
                    Positioned(
                      top: 60,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.glassGradient ?? chinguTheme?.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 18,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayUser.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${displayUser.ratingCount})',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
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
                                Flexible(
                                  child: Text(
                                    '${displayUser.name}, ${displayUser.age}',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: displayUser.isActive
                                        ? (chinguTheme?.success ?? Colors.green)
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayUser.job.isNotEmpty ? displayUser.job : '未填寫職業',
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
                    '${displayUser.city}, ${displayUser.district}',
                    theme.colorScheme.primary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.payments_rounded,
                    '預算範圍',
                    displayUser.budgetRangeText,
                    chinguTheme?.secondary ?? theme.colorScheme.secondary,
                    theme,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    Icons.favorite_rounded,
                    '配對類型',
                    displayUser.preferredMatchTypeText,
                    chinguTheme?.error ?? theme.colorScheme.error,
                    theme,
                  ),
                  if (displayUser.ratingCount > 0) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      Icons.star_rounded,
                      '用戶評分',
                      '${displayUser.averageRating.toStringAsFixed(1)} / 5.0',
                      Colors.amber,
                      theme,
                    ),
                  ],
                  
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
                      displayUser.bio?.isNotEmpty == true
                          ? displayUser.bio!
                          : '這個人很懶，什麼都沒寫...',
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
                  if (displayUser.interests.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: displayUser.interests.map((interest) =>
                        _buildInterestChip(interest, Icons.star_border_rounded, theme.colorScheme.primary)
                      ).toList(),
                    )
                  else
                    Text(
                      '未填寫興趣',
                      style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  
                  const SizedBox(height: 32),
                  
                  // 操作按鈕
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
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
                                // TODO: Implement Like logic
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
