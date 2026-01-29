import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Topic mappings
  final Map<String, String> _locationTopics = {
    'topic_loc_taipei': '台北',
    'topic_loc_taichung': '台中',
    'topic_loc_kaohsiung': '高雄',
  };

  final Map<String, String> _interestTopics = {
    'topic_int_food': '美食',
    'topic_int_travel': '旅遊',
    'topic_int_tech': '科技',
    'topic_int_art': '藝術',
    'topic_int_social': '社交',
  };

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    // Loading state for initial data or processing
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('通知設定')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subscribedTopics = user.subscribedTopics;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              _buildSectionTitle(context, '主題訂閱'),
              _buildSubsectionTitle(context, '地區'),
              ..._locationTopics.entries.map((entry) {
                final isSubscribed = subscribedTopics.contains(entry.key);
                return SwitchListTile(
                  title: Text(entry.value),
                  value: isSubscribed,
                  onChanged: (val) => _handleTopicToggle(entry.key, val, authProvider),
                  activeColor: theme.colorScheme.primary,
                );
              }),
              _buildSubsectionTitle(context, '興趣'),
              ..._interestTopics.entries.map((entry) {
                final isSubscribed = subscribedTopics.contains(entry.key);
                return SwitchListTile(
                  title: Text(entry.value),
                  value: isSubscribed,
                  onChanged: (val) => _handleTopicToggle(entry.key, val, authProvider),
                  activeColor: theme.colorScheme.primary,
                );
              }),

              const Divider(),
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true, // TODO: Implement global switch
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              ListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text('總是顯示', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.notificationPreview);
                },
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildSubsectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _handleTopicToggle(
    String topic,
    bool value,
    AuthProvider authProvider,
  ) async {
    setState(() => _isLoading = true);

    try {
      final richNotificationService = RichNotificationService();

      // 1. Update FCM
      if (value) {
        await richNotificationService.subscribeToTopic(topic);
      } else {
        await richNotificationService.unsubscribeFromTopic(topic);
      }

      // 2. Update Firestore/User Model
      final user = authProvider.userModel!;
      final currentTopics = List<String>.from(user.subscribedTopics);

      if (value) {
        if (!currentTopics.contains(topic)) {
          currentTopics.add(topic);
        }
      } else {
        currentTopics.remove(topic);
      }

      final success = await authProvider.updateUserData({
        'subscribedTopics': currentTopics,
      });

      if (!success) {
         // Revert FCM if firestore update failed?
         // For now just show error.
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(authProvider.errorMessage ?? '更新失敗')),
           );
         }
         // Revert subscription
         if (value) {
           await richNotificationService.unsubscribeFromTopic(topic);
         } else {
           await richNotificationService.subscribeToTopic(topic);
         }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
