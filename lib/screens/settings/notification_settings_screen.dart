import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  // Topic definitions
  static const Map<String, String> _regionTopics = {
    '台北 (Taipei)': 'region_taipei',
    '台中 (Taichung)': 'region_taichung',
    '高雄 (Kaohsiung)': 'region_kaohsiung',
  };

  static const Map<String, String> _interestTopics = {
    '戶外 (Outdoors)': 'interest_outdoors',
    '美食 (Food)': 'interest_food',
    '藝文 (Arts)': 'interest_arts',
    '科技 (Tech)': 'interest_tech',
    '音樂 (Music)': 'interest_music',
  };
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;
          final subscribedTopics = user?.subscribedTopics ?? [];
          final isLoading = authProvider.isLoading;

          return ListView(
            children: [
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),

              const Divider(),
              _buildSectionTitle(context, '地區訂閱 (Region Subscription)'),
              ..._regionTopics.entries.map((entry) {
                final label = entry.key;
                final topic = entry.value;
                final isSubscribed = subscribedTopics.contains(topic);

                return CheckboxListTile(
                  title: Text(label),
                  value: isSubscribed,
                  enabled: !isLoading,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (bool? value) {
                    _toggleTopic(context, authProvider, topic, value == true);
                  },
                );
              }),

              const Divider(),
              _buildSectionTitle(context, '興趣訂閱 (Interest Subscription)'),
              ..._interestTopics.entries.map((entry) {
                final label = entry.key;
                final topic = entry.value;
                final isSubscribed = subscribedTopics.contains(topic);

                return CheckboxListTile(
                  title: Text(label),
                  value: isSubscribed,
                  enabled: !isLoading,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (bool? value) {
                    _toggleTopic(context, authProvider, topic, value == true);
                  },
                );
              }),

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
          );
        },
      ),
    );
  }
  
  void _toggleTopic(BuildContext context, AuthProvider authProvider, String topic, bool subscribe) {
    if (authProvider.isLoading) return; // Extra safety check

    final currentTopics = List<String>.from(authProvider.userModel?.subscribedTopics ?? []);

    if (subscribe) {
      if (!currentTopics.contains(topic)) {
        currentTopics.add(topic);
      }
    } else {
      currentTopics.remove(topic);
    }

    authProvider.updateSubscribedTopics(currentTopics);
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
}
