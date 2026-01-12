import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_header.dart';
import 'package:chingu/widgets/animated_counter.dart';

class StatsDashboardScreen extends StatelessWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate derived stats
          // Chat Activity: Mock calculation based on matches and events
          // In a real app, this would come from message counts
          final chatActivityScore = (user.totalMatches * 5 + user.totalDinners * 10).clamp(0, 100);

          return Column(
            children: [
              GradientHeader(
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Expanded(
                            child: Text(
                              '個人統計儀表板',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance the back button
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCard(context, user.totalMatches, user.totalDinners, chatActivityScore),
                      const SizedBox(height: 24),
                      Text(
                        '詳細數據',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        context,
                        '配對次數',
                        user.totalMatches,
                        Icons.favorite_rounded,
                        const Color(0xFFFF6B6B),
                        '已成功配對的次數',
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        context,
                        '活動參與',
                        user.totalDinners,
                        Icons.event_available_rounded,
                        const Color(0xFF4ECDC4),
                        '已參加的聚餐活動',
                      ),
                      const SizedBox(height: 16),
                      _buildDetailCard(
                        context,
                        '聊天活躍度',
                        chatActivityScore,
                        Icons.chat_bubble_rounded,
                        const Color(0xFFFFD166),
                        '基於互動頻率的活躍指數',
                        suffix: '%',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int matches, int dinners, int chatScore) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSummaryItem(context, '配對', matches),
          _buildDivider(),
          _buildSummaryItem(context, '活動', dinners),
          _buildDivider(),
          _buildSummaryItem(context, '活躍度', chatScore, suffix: '%'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, num value, {String suffix = ''}) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AnimatedCounter(
          value: value,
          suffix: suffix,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildDetailCard(
    BuildContext context,
    String title,
    num value,
    IconData icon,
    Color color,
    String description,
    {String suffix = ''}
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          AnimatedCounter(
            value: value,
            suffix: suffix,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
