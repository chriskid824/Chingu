import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/chat_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  bool _isLoading = true;
  int _eventCount = 0;
  int _activeChatCount = 0;

  // Breakdown of events
  int _upcomingEvents = 0;
  int _completedEvents = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = context.read<AuthProvider>().userModel?.uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Load events
      final dinnerService = DinnerEventService();
      final events = await dinnerService.getUserEvents(userId);

      final now = DateTime.now();
      int upcoming = 0;
      int completed = 0;

      for (var event in events) {
        if (event.dateTime.isAfter(now)) {
          upcoming++;
        } else {
          completed++;
        }
      }

      // Load chats
      // We can use ChatProvider if it's already loaded, or force reload.
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.chatRooms.isEmpty) {
        await chatProvider.loadChatRooms(userId);
      }

      if (mounted) {
        setState(() {
          _eventCount = events.length;
          _upcomingEvents = upcoming;
          _completedEvents = completed;
          _activeChatCount = chatProvider.chatRooms.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      appBar: AppBar(
        title: const Text('個人統計儀表板'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleTextStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(context, user.totalMatches),
                    const SizedBox(height: 24),
                    Text(
                      '詳細數據',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: '配對次數',
                            value: user.totalMatches.toString(),
                            icon: Icons.favorite_rounded,
                            color: Colors.pinkAccent,
                            subtitle: '總共配對',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            context,
                            title: '聊天活躍度',
                            value: _activeChatCount.toString(),
                            icon: Icons.chat_bubble_rounded,
                            color: Colors.blueAccent,
                            subtitle: '活躍聊天室',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildEventStatsCard(context),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, int totalMatches) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '總體表現',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(totalMatches + _eventCount)}', // Just a made up "Engagement Score" or total interactions
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '互動總次數',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewItem('配對', totalMatches.toString()),
              _buildVerticalDivider(),
              _buildOverviewItem('聚餐', _eventCount.toString()),
              _buildVerticalDivider(),
              _buildOverviewItem('聊天', _activeChatCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventStatsCard(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_note_rounded, color: Colors.orangeAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                '活動參與',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _upcomingEvents.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('即將參加'),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.dividerColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _completedEvents.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('已完成'),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: theme.dividerColor,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _eventCount.toString(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('總計'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
