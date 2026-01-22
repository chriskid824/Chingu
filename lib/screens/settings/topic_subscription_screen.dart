import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/notification_service.dart';
import '../../providers/auth_provider.dart';

class TopicSubscriptionScreen extends StatefulWidget {
  const TopicSubscriptionScreen({super.key});

  @override
  State<TopicSubscriptionScreen> createState() => _TopicSubscriptionScreenState();
}

class _TopicSubscriptionScreenState extends State<TopicSubscriptionScreen> {
  // 定義可用的主題
  final Map<String, String> _locations = {
    'loc_taipei': '台北',
    'loc_taichung': '台中',
    'loc_kaohsiung': '高雄',
  };

  final Map<String, String> _interests = {
    'int_food': '美食',
    'int_movies': '電影',
    'int_outdoors': '戶外活動',
    'int_tech': '科技',
    'int_music': '音樂',
    'int_travel': '旅遊',
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userModel = context.watch<AuthProvider>().userModel;
    final subscribedTopics = userModel?.subscribedTopics ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('主題訂閱', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader(context, '地區訂閱'),
                const SizedBox(height: 8),
                Text(
                  '訂閱您感興趣的地區，接收當地的熱門活動通知',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ..._locations.entries.map((entry) => _buildSubscriptionTile(
                      context,
                      entry.key,
                      entry.value,
                      subscribedTopics.contains(entry.key),
                    )),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                _buildSectionHeader(context, '興趣訂閱'),
                const SizedBox(height: 8),
                Text(
                  '根據您的興趣接收相關推薦與資訊',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ..._interests.entries.map((entry) => _buildSubscriptionTile(
                      context,
                      entry.key,
                      entry.value,
                      subscribedTopics.contains(entry.key),
                    )),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSubscriptionTile(
    BuildContext context,
    String topicId,
    String title,
    bool isSubscribed,
  ) {
    return SwitchListTile(
      title: Text(title),
      value: isSubscribed,
      activeColor: Theme.of(context).colorScheme.primary,
      onChanged: (bool value) async {
        setState(() {
          _isLoading = true;
        });

        try {
          final notificationService = NotificationService();
          if (value) {
            await notificationService.subscribeToTopic(topicId);
          } else {
            await notificationService.unsubscribeFromTopic(topicId);
          }

          // 重新加載用戶數據以更新 UI
          if (mounted) {
            await context.read<AuthProvider>().loadUserData();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('操作失敗: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
    );
  }
}
