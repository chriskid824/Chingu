import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/stats_service.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final StatsService _statsService = StatsService();
  Future<UserStats>? _statsFuture;

  @override
  void initState() {
    super.initState();
    // 在 initState 中初始化 Future，避免重建時重複請求
    // 注意：這裡假設進入此頁面時 AuthProvider 已有 userModel
    // 如果沒有，會在 build 中處理或延遲
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_statsFuture == null) {
      final userId = context.read<AuthProvider>().userModel?.uid;
      if (userId != null) {
        _statsFuture = _statsService.getUserStats(userId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = context.watch<AuthProvider>().userModel?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('個人統計儀表板')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '個人統計儀表板',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: FutureBuilder<UserStats>(
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
                    onPressed: () {
                      setState(() {
                        _statsFuture = _statsService.getUserStats(userId);
                      });
                    },
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data;
          if (stats == null) {
            return const Center(child: Text('無數據'));
          }

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Text(
                '使用概況',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // 使用 GridView 顯示卡片
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true, // 允許在 ListView 中使用
                physics: const NeverScrollableScrollPhysics(), // 禁用 GridView 滾動
                children: [
                  _buildStatCard(
                    context,
                    '配對成功',
                    stats.matchCount,
                    Icons.favorite_rounded,
                    Colors.pinkAccent,
                    '次',
                  ),
                  _buildStatCard(
                    context,
                    '活動參與',
                    stats.eventCount,
                    Icons.restaurant_rounded,
                    Colors.orangeAccent,
                    '場',
                  ),
                  _buildStatCard(
                    context,
                    '聊天活躍度',
                    stats.chatCount,
                    Icons.chat_bubble_rounded,
                    Colors.blueAccent,
                    '個對話',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // 底部提示
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '聊天活躍度代表您目前參與的活躍聊天室數量。',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
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
    int count,
    IconData icon,
    Color color,
    String unit,
  ) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
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
          Text(
            count.toString(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$title ($unit)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
