import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_header.dart';
import 'package:chingu/widgets/animated_counter.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  int _messageCount = 0;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _loadMessageStats();
  }

  Future<void> _loadMessageStats() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    try {
      final countQuery = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: user.uid)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _messageCount = countQuery.count ?? 0;
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading message stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingMessages = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

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
                          const SizedBox(width: 48), // Balance back button
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${user.name} 的使用概況',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '配對次數',
                              user.totalMatches,
                              Icons.favorite_rounded,
                              Colors.pinkAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '活動參與',
                              user.totalDinners,
                              Icons.restaurant_rounded,
                              Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '聊天活躍度',
                              _isLoadingMessages ? null : _messageCount,
                              Icons.chat_bubble_rounded,
                              Colors.blueAccent,
                              subtitle: '已發送訊息數',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '平均評分',
                              user.averageRating,
                              Icons.star_rounded,
                              Colors.amber,
                              isRating: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildEngagementSection(context),
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    num? value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isRating = false,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          if (value == null)
            const SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            AnimatedCounter(
              value: value,
              decimalPlaces: isRating ? 1 : 0,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEngagementSection(BuildContext context) {
    final theme = Theme.of(context);

    // 根據活躍度給予評語
    String getEngagementLevel() {
      if (_isLoadingMessages) return '計算中...';
      if (_messageCount > 100) return '社交達人';
      if (_messageCount > 20) return '活躍成員';
      return '潛力新星';
    }

    String getEngagementDescription() {
      if (_isLoadingMessages) return '';
      if (_messageCount > 100) return '您非常熱衷於認識新朋友！繼續保持！';
      if (_messageCount > 20) return '您已經開始建立連結，多參加活動可以認識更多人喔！';
      return '主動發起對話是認識新朋友的第一步！';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '社交成就',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            getEngagementLevel(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getEngagementDescription(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
