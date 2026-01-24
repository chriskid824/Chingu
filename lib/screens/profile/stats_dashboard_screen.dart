import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/animated_counter.dart';
import 'package:chingu/models/user_model.dart';

class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('統計儀表板')),
        body: const Center(child: Text('無法載入資料')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('個人統計儀表板'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(context, user),
            const SizedBox(height: 32),
            Text(
              '詳細數據',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatTile(
              context,
              icon: Icons.favorite_rounded,
              color: Colors.pink,
              title: '配對次數',
              value: user.totalMatches,
              subtitle: '您已配對成功的總次數',
            ),
            const SizedBox(height: 12),
            _buildStatTile(
              context,
              icon: Icons.restaurant_rounded,
              color: Colors.orange,
              title: '活動參與',
              value: user.totalDinners,
              subtitle: '您已參加的聚餐與活動總數',
            ),
            const SizedBox(height: 12),
            _buildStatTile(
              context,
              icon: Icons.chat_bubble_rounded,
              color: Colors.blue,
              title: '聊天活躍度',
              value: user.totalMessagesSent,
              subtitle: '您已發送的訊息總數',
            ),
            const SizedBox(height: 12),
            _buildStatTile(
              context,
              icon: Icons.star_rounded,
              color: Colors.amber,
              title: '平均評分',
              value: user.averageRating,
              subtitle: '來自其他用戶的評價',
              isRating: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection(BuildContext context, UserModel user) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: chinguTheme?.primaryGradient ??
            LinearGradient(colors: [theme.primaryColor, theme.primaryColor]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (chinguTheme?.primaryGradient.colors.first ?? theme.primaryColor)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '綜合表現',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem(context, '配對', user.totalMatches),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildOverviewItem(context, '活動', user.totalDinners),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildOverviewItem(context, '訊息', user.totalMessagesSent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(BuildContext context, String label, int value) {
    return Column(
      children: [
        AnimatedCounter(
          value: value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required num value,
    required String subtitle,
    bool isRating = false,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: chinguTheme?.surfaceVariant ?? Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCounter(
            value: value,
            decimalPlaces: isRating ? 1 : 0,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
