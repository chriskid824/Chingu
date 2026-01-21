import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_header.dart';
import 'package:chingu/widgets/animated_counter.dart';
import 'package:chingu/core/theme/app_theme.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  int _activeChatCount = 0;
  bool _isLoadingChatCount = true;

  @override
  void initState() {
    super.initState();
    _fetchChatCount();
  }

  Future<void> _fetchChatCount() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    try {
      final countQuery = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participantIds', arrayContains: user.uid)
          .count()
          .get();

      if (mounted) {
        setState(() {
          _activeChatCount = countQuery.count ?? 0;
          _isLoadingChatCount = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching chat count: $e');
      if (mounted) {
        setState(() {
          _isLoadingChatCount = false;
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

          return RefreshIndicator(
            onRefresh: () async {
              await authProvider.refreshUserData();
              await _fetchChatCount();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
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
                              const SizedBox(width: 48), // Balance for title alignment
                            ],
                          ),
                          const Text(
                            '個人統計儀表板',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildStatCard(
                          context,
                          title: '配對次數',
                          value: user.totalMatches,
                          icon: Icons.favorite_rounded,
                          color: Colors.pinkAccent,
                          description: '成功配對的總次數',
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          context,
                          title: '活動參與',
                          value: user.totalDinners,
                          icon: Icons.event_available_rounded,
                          color: Colors.orangeAccent,
                          description: '參加過的聚餐活動',
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          context,
                          title: '活躍聊天室',
                          value: _activeChatCount,
                          isLoading: _isLoadingChatCount,
                          icon: Icons.chat_bubble_rounded,
                          color: Colors.blueAccent,
                          description: '目前參與的聊天室數量',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required num value,
    required IconData icon,
    required Color color,
    String? description,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  AnimatedCounter(
                    value: value,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                if (description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
