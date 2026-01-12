import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/topic_subscription_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = user.notificationSettings;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
          ),
          body: ListView(
            children: [
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['push_enabled'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'push_enabled', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),

              _buildSectionTitle(context, '主題訂閱'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text('根據您的地區和興趣接收相關推送', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ),
              _buildRegionSubscription(context, user, authProvider),
              _buildInterestSubscription(context, user, authProvider),

              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['match_new'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'match_new', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['match_success'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'match_success', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['message_new'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'message_new', v),
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
                value: settings['event_reminder'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'event_reminder', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['event_change'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'event_change', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['marketing_promo'] ?? false,
                onChanged: (v) => _updateSetting(context, authProvider, 'marketing_promo', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['marketing_newsletter'] ?? false,
                onChanged: (v) => _updateSetting(context, authProvider, 'marketing_newsletter', v),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegionSubscription(BuildContext context, UserModel user, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final regions = [
      {'name': '台北 (Taipei)', 'key': 'taipei'},
      {'name': '台中 (Taichung)', 'key': 'taichung'},
      {'name': '高雄 (Kaohsiung)', 'key': 'kaohsiung'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('地區訂閱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ),
        ...regions.map((region) {
          final topic = TopicSubscriptionService.formatLocationTopic(region['key']!);
          final isSubscribed = user.subscribedTopics.contains(topic);

          return CheckboxListTile(
            title: Text(region['name']!),
            value: isSubscribed,
            onChanged: (bool? value) {
              if (value != null) {
                _updateTopicSubscription(context, authProvider, topic, value);
              }
            },
            activeColor: theme.colorScheme.primary,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          );
        }),
      ],
    );
  }

  Widget _buildInterestSubscription(BuildContext context, UserModel user, AuthProvider authProvider) {
    final theme = Theme.of(context);

    if (user.interests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('興趣訂閱', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: user.interests.map((interest) {
              final topic = TopicSubscriptionService.formatInterestTopic(interest);
              final isSubscribed = user.subscribedTopics.contains(topic);

              return FilterChip(
                label: Text(interest),
                selected: isSubscribed,
                onSelected: (bool value) {
                  _updateTopicSubscription(context, authProvider, topic, value);
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                checkmarkColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
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

  Future<void> _updateSetting(
    BuildContext context,
    AuthProvider authProvider,
    String key,
    bool value,
  ) async {
    final currentSettings = Map<String, bool>.from(authProvider.userModel!.notificationSettings);
    currentSettings[key] = value;

    await authProvider.updateUserData({
      'notificationSettings': currentSettings,
    });
  }

  Future<void> _updateTopicSubscription(
    BuildContext context,
    AuthProvider authProvider,
    String topic,
    bool isSubscribing,
  ) async {
    final currentTopics = List<String>.from(authProvider.userModel!.subscribedTopics);

    if (isSubscribing) {
      if (!currentTopics.contains(topic)) {
        currentTopics.add(topic);
        await TopicSubscriptionService().subscribeToTopic(topic);
      }
    } else {
      if (currentTopics.contains(topic)) {
        currentTopics.remove(topic);
        await TopicSubscriptionService().unsubscribeFromTopic(topic);
      }
    }

    await authProvider.updateUserData({
      'subscribedTopics': currentTopics,
    });
  }
}
