import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/chat_service.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final DinnerEventService _dinnerEventService = DinnerEventService();
  final ChatService _chatService = ChatService();

  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<Map<String, dynamic>> _loadStats() async {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    try {
      final results = await Future.wait([
        // 0: Events count
        _dinnerEventService.getUserEvents(userId).then((events) => events.length),
        // 1: Chat count
        _chatService.getUserChatCount(userId),
      ]);

      return {
        'eventsCount': results[0],
        'chatsCount': results[1],
      };
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = _loadStats();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.select((AuthProvider p) => p.userModel);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人統計儀表板'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStats,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

          final data = snapshot.data ?? {'eventsCount': 0, 'chatsCount': 0};
          final eventsCount = data['eventsCount'] as int;
          final chatsCount = data['chatsCount'] as int;
          final matchesCount = user.totalMatches;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildStatCard(
                context,
                title: '配對次數',
                value: matchesCount.toString(),
                icon: Icons.favorite,
                color: Colors.pink,
                description: '您成功配對的次數',
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                title: '活動參與',
                value: eventsCount.toString(),
                icon: Icons.event,
                color: Colors.orange,
                description: '您參加過的晚餐活動',
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                context,
                title: '聊天活躍度',
                value: chatsCount.toString(),
                icon: Icons.chat_bubble,
                color: Colors.blue,
                description: '您正在參與的聊天室',
              ),

              const SizedBox(height: 32),

              // 總結卡片
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        '社交活躍指數',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: CircularProgressIndicator(
                              value: _calculateActivityScore(matchesCount, eventsCount, chatsCount),
                              strokeWidth: 12,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                            ),
                          ),
                          Text(
                            '${(_calculateActivityScore(matchesCount, eventsCount, chatsCount) * 100).toInt()}%',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '保持活躍，認識更多新朋友！',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
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

  double _calculateActivityScore(int matches, int events, int chats) {
    // 簡單的活躍度算法，僅供展示
    // 假設目標是：10個配對，5個活動，5個聊天
    double score = (matches * 2 + events * 5 + chats * 3) / 60.0;
    return score.clamp(0.0, 1.0);
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

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
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
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
