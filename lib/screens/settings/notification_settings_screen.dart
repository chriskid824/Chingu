import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/topic_subscription_service.dart';
import 'package:chingu/core/constants/notification_topics.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topicService = TopicSubscriptionService();

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
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscribedRegions = user.subscribedRegions;
          final subscribedTopics = user.subscribedTopics;

          return ListView(
            children: [
              _buildSectionTitle(context, '地區訂閱 (接收該地區活動通知)'),
              ...NotificationTopics.availableRegions.map((region) {
                final isSubscribed = subscribedRegions.contains(region);
                return CheckboxListTile(
                  title: Text(NotificationTopics.regionDisplayNames[region] ?? region),
                  value: isSubscribed,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (bool? value) async {
                    if (value == null) return;
                    try {
                      await topicService.updateRegionSubscription(
                        userId: user.uid,
                        region: region,
                        isSubscribed: value,
                      );
                      // Refresh user data to update UI
                      await authProvider.refreshUserData();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('更新失敗: $e')),
                        );
                      }
                    }
                  },
                );
              }),

              const Divider(),
              _buildSectionTitle(context, '主題訂閱 (接收相關興趣通知)'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: NotificationTopics.availableTopics.map((topic) {
                    final isSubscribed = subscribedTopics.contains(topic);
                    return FilterChip(
                      label: Text(NotificationTopics.topicDisplayNames[topic] ?? topic),
                      selected: isSubscribed,
                      onSelected: (bool selected) async {
                        try {
                          await topicService.updateTopicSubscription(
                            userId: user.uid,
                            topic: topic,
                            isSubscribed: selected,
                          );
                          await authProvider.refreshUserData();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('更新失敗: $e')),
                            );
                          }
                        }
                      },
                      selectedColor: theme.colorScheme.primaryContainer,
                      checkmarkColor: theme.colorScheme.primary,
                    );
                  }).toList(),
                ),
              ),

              const Divider(),
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true,
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
            ],
          );
        },
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
}
