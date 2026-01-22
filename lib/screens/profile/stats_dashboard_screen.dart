import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/widgets/gradient_header.dart';
import 'package:chingu/widgets/animated_counter.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final ChatService _chatService = ChatService();
  late Future<int> _chatCountFuture;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _chatCountFuture = _chatService.getChatRoomCount(user.uid);
    } else {
      _chatCountFuture = Future.value(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
                      const Text(
                        '統計儀表板',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      '您的活動統計',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
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
                    icon: Icons.restaurant_menu_rounded,
                    color: Colors.orangeAccent,
                    description: '參加過的聚餐活動',
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<int>(
                    future: _chatCountFuture,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return _buildStatCard(
                        context,
                        title: '聊天活躍度',
                        value: count,
                        icon: Icons.chat_bubble_rounded,
                        color: Colors.blueAccent,
                        description: '正在進行的聊天對話',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildStatCard(
                    context,
                    title: '平均評分',
                    value: user.averageRating,
                    icon: Icons.star_rounded,
                    color: Colors.amber,
                    description: '來自其他用戶的評價',
                    isRating: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required num value,
    required IconData icon,
    required Color color,
    required String description,
    bool isRating = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
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
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
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
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
