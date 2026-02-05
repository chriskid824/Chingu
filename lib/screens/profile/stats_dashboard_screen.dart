import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_header.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<Map<String, int>> _fetchStats() async {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null) return {'events': 0, 'chats': 0};

    final eventCount = await DinnerEventService().getUserEventCount(userId);
    final chatCount = await ChatService().getUserChatRoomCount(userId);

    return {
      'events': eventCount,
      'chats': chatCount,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
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
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance back button
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '查看您的使用數據與活躍度',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, int>>(
              future: _statsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('載入失敗: ${snapshot.error}'));
                }

                final stats = snapshot.data ?? {'events': 0, 'chats': 0};
                final eventCount = stats['events']!;
                final chatCount = stats['chats']!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatCard(
                        context,
                        title: '配對次數',
                        value: user.totalMatches.toString(),
                        icon: Icons.favorite_rounded,
                        color: Colors.pink,
                        description: '成功配對的總次數',
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        context,
                        title: '活動參與',
                        value: eventCount.toString(),
                        icon: Icons.event_available_rounded,
                        color: Colors.orange,
                        description: '已報名或參與的晚餐活動',
                      ),
                      const SizedBox(height: 16),
                      _buildStatCard(
                        context,
                        title: '聊天活躍度',
                        value: chatCount.toString(),
                        icon: Icons.chat_bubble_rounded,
                        color: Colors.blue,
                        description: '參與的聊天室總數',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String description,
  }) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
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
            padding: const EdgeInsets.all(12),
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
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
