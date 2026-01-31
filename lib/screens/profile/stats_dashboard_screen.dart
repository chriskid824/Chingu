import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/services/stats_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/animated_counter.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final StatsService _statsService = StatsService();
  UserStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      try {
        final stats = await _statsService.getUserStats(
          user.uid,
          currentMatchCount: user.totalMatches,
        );
        if (mounted) {
          setState(() {
            _stats = stats;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('載入統計資料失敗: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人統計儀表板'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('無法載入統計資料'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        context,
                        title: '配對次數',
                        value: _stats!.matchCount,
                        icon: Icons.favorite_rounded,
                        color: Colors.pinkAccent,
                      ),
                      _buildStatCard(
                        context,
                        title: '活動參與',
                        value: _stats!.eventCount,
                        icon: Icons.event_available_rounded,
                        color: Colors.orangeAccent,
                      ),
                      _buildStatCard(
                        context,
                        title: '聊天活躍度',
                        value: _stats!.chatCount,
                        icon: Icons.chat_bubble_rounded,
                        color: Colors.blueAccent,
                        subtitle: '個活躍聊天室',
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const Spacer(),
            AnimatedCounter(
              value: value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
