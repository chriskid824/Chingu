import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/chat_service.dart';

class StatsDashboardScreen extends StatefulWidget {
  const StatsDashboardScreen({super.key});

  @override
  State<StatsDashboardScreen> createState() => _StatsDashboardScreenState();
}

class _StatsDashboardScreenState extends State<StatsDashboardScreen> {
  final ChatService _chatService = ChatService();
  int _activeChatsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    // Wait for frame to ensure context is available if needed, though initState is fine for provider read if listen: false
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;

    if (user != null) {
      try {
        final count = await _chatService.getChatRoomCount(user.uid);
        if (mounted) {
          setState(() {
            _activeChatsCount = count;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Error fetching stats: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
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
    final user = context.select<AuthProvider, UserModel?>((p) => p.userModel);

    if (user == null) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計儀表板'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      extendBodyBehindAppBar: false,
      body: Container(
         decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withOpacity(0.05),
                theme.scaffoldBackgroundColor,
              ],
            ),
          ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _fetchStats,
            child: ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildSummaryCard(context, user),
                const SizedBox(height: 24),
                Text(
                  '詳細數據',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildStatCard(
                      context,
                      title: '配對次數',
                      value: user.totalMatches.toString(),
                      icon: Icons.favorite_rounded,
                      color: Colors.pink,
                    ),
                    _buildStatCard(
                      context,
                      title: '活動參與',
                      value: user.totalDinners.toString(),
                      icon: Icons.event_available_rounded,
                      color: Colors.orange,
                    ),
                    _buildStatCard(
                      context,
                      title: '聊天活躍度',
                      value: _isLoading ? '...' : _activeChatsCount.toString(),
                      subtitle: '活躍聊天室',
                      icon: Icons.chat_bubble_rounded,
                      color: Colors.blue,
                    ),
                     _buildStatCard(
                      context,
                      title: '平均評分',
                      value: user.averageRating.toStringAsFixed(1),
                      icon: Icons.star_rounded,
                      color: Colors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, UserModel user) {
     final theme = Theme.of(context);
     return Card(
       elevation: 2,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Padding(
         padding: const EdgeInsets.all(20),
         child: Row(
           children: [
             Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                  child: user.avatarUrl == null
                    ? Icon(Icons.person, color: theme.colorScheme.primary)
                    : null,
                ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     user.name,
                     style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 4),
                   Text(
                     '會員自: ${user.createdAt.year}/${user.createdAt.month.toString().padLeft(2, '0')}/${user.createdAt.day.toString().padLeft(2, '0')}',
                     style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
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
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
             if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                ),
             ]
          ],
        ),
      ),
    );
  }
}
