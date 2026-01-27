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
  late Future<int> _activeChatsCountFuture;

  @override
  void initState() {
    super.initState();
    _activeChatsCountFuture = _fetchActiveChatsCount();
  }

  Future<int> _fetchActiveChatsCount() async {
    final user = context.read<AuthProvider>().userModel;
    if (user == null) return 0;

    try {
      final aggregateQuery = FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participantIds', arrayContains: user.uid)
          .count();

      final snapshot = await aggregateQuery.get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error fetching chat count: $e');
      return 0;
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
                              '統計儀表板',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${user.name} 的使用概況',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
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
                        icon: Icons.restaurant_rounded,
                        color: Colors.orangeAccent,
                        description: '已參加的聚餐活動',
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<int>(
                        future: _activeChatsCountFuture,
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return _buildStatCard(
                            context,
                            title: '聊天活躍度',
                            value: count,
                            icon: Icons.chat_bubble_rounded,
                            color: Colors.blueAccent,
                            description: '目前的活躍聊天室數量',
                            isLoading: snapshot.connectionState == ConnectionState.waiting,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Example of a combined metric or rating if needed
                       _buildStatCard(
                        context,
                        title: '平均評分',
                        value: user.averageRating,
                        isFloat: true,
                        icon: Icons.star_rounded,
                        color: Colors.amber,
                        description: '來自其他用戶的評價',
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

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required num value,
    required IconData icon,
    required Color color,
    required String description,
    bool isLoading = false,
    bool isFloat = false,
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
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLoading)
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                else
                  AnimatedCounter(
                    value: value,
                    decimalPlaces: isFloat ? 1 : 0,
                    style: theme.textTheme.headlineMedium?.copyWith(
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
    );
  }
}
