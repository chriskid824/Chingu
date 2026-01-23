import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/user_stats_service.dart';
import 'package:chingu/widgets/animated_counter.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final UserStatsService _userStatsService = UserStatsService();
  late Future<Map<String, int>> _statsFuture;

  @override
  void initState() {
    super.initState();
    // Use listen: false to access provider in initState
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId != null) {
      _statsFuture = _userStatsService.getUserStats(userId);
    } else {
      _statsFuture = Future.error('未找到用戶資料');
    }
  }

  void _refreshStats() {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId != null) {
      setState(() {
        _statsFuture = _userStatsService.getUserStats(userId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('個人統計儀表板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('載入失敗: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStats,
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          final user = context.watch<AuthProvider>().userModel;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  context,
                  '配對次數',
                  stats['matches'] ?? 0,
                  Icons.favorite_rounded,
                  Colors.pink,
                ),
                _buildStatCard(
                  context,
                  '活動參與',
                  stats['events'] ?? 0,
                  Icons.event_available_rounded,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  '聊天活躍度',
                  stats['chats'] ?? 0,
                  Icons.chat_bubble_rounded,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  '平均評分',
                  user?.averageRating ?? 0,
                  Icons.star_rounded,
                  Colors.amber,
                  isRating: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    num count,
    IconData icon,
    Color color,
    {bool isRating = false}
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          AnimatedCounter(
            value: count,
            decimalPlaces: isRating ? 1 : 0,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
