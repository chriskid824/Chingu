import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';
import 'package:chingu/services/topic_subscription_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final TopicSubscriptionService _topicService = TopicSubscriptionService();

  // 定義地區和興趣的對照表
  final Map<String, String> _regions = {
    'taipei': '台北',
    'taichung': '台中',
    'kaohsiung': '高雄',
  };

  final Map<String, String> _interests = {
    'food': '美食',
    'movie': '電影',
    'outdoors': '戶外',
    'music': '音樂',
    'tech': '科技',
  };

  Future<void> _updateSettings(BuildContext context, NotificationSettings newSettings) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return;

    // 更新 Firestore
    await authProvider.updateUserData({
      'notificationSettings': newSettings.toMap(),
    });
  }

  Future<void> _toggleRegionSubscription(BuildContext context, String regionCode, bool subscribe) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentSettings = authProvider.userModel?.notificationSettings ?? const NotificationSettings();

    List<String> currentRegions = List.from(currentSettings.subscribedRegions);

    if (subscribe) {
      if (!currentRegions.contains(regionCode)) {
        currentRegions.add(regionCode);
        await _topicService.subscribeToTopic('region_$regionCode');
      }
    } else {
      if (currentRegions.contains(regionCode)) {
        currentRegions.remove(regionCode);
        await _topicService.unsubscribeFromTopic('region_$regionCode');
      }
    }

    await _updateSettings(context, currentSettings.copyWith(subscribedRegions: currentRegions));
  }

  Future<void> _toggleInterestSubscription(BuildContext context, String interestCode, bool subscribe) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentSettings = authProvider.userModel?.notificationSettings ?? const NotificationSettings();

    List<String> currentInterests = List.from(currentSettings.subscribedInterests);

    if (subscribe) {
      if (!currentInterests.contains(interestCode)) {
        currentInterests.add(interestCode);
        await _topicService.subscribeToTopic('interest_$interestCode');
      }
    } else {
      if (currentInterests.contains(interestCode)) {
        currentInterests.remove(interestCode);
        await _topicService.unsubscribeFromTopic('interest_$interestCode');
      }
    }

    await _updateSettings(context, currentSettings.copyWith(subscribedInterests: currentInterests));
  }

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
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = user.notificationSettings;

          return ListView(
            children: [
              _buildSectionTitle(context, '地區訂閱'),
              ..._regions.entries.map((entry) {
                final isSubscribed = settings.subscribedRegions.contains(entry.key);
                return SwitchListTile(
                  title: Text(entry.value),
                  subtitle: Text('接收${entry.value}地區的相關通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: isSubscribed,
                  onChanged: (v) => _toggleRegionSubscription(context, entry.key, v),
                  activeColor: theme.colorScheme.primary,
                );
              }),
              const Divider(),

              _buildSectionTitle(context, '興趣訂閱'),
              ..._interests.entries.map((entry) {
                final isSubscribed = settings.subscribedInterests.contains(entry.key);
                return SwitchListTile(
                  title: Text(entry.value),
                  subtitle: Text('接收${entry.value}相關的通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: isSubscribed,
                  onChanged: (v) => _toggleInterestSubscription(context, entry.key, v),
                  activeColor: theme.colorScheme.primary,
                );
              }),
              const Divider(),

              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.pushEnabled,
                onChanged: (v) => _updateSettings(context, settings.copyWith(pushEnabled: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),

              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.newMatch,
                onChanged: (v) => _updateSettings(context, settings.copyWith(newMatch: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.matchSuccess,
                onChanged: (v) => _updateSettings(context, settings.copyWith(matchSuccess: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),

              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.newMessage,
                onChanged: (v) => _updateSettings(context, settings.copyWith(newMessage: v)),
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
                value: settings.eventUpdate,
                onChanged: (v) => _updateSettings(context, settings.copyWith(eventUpdate: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),

              _buildSectionTitle(context, '系統通知'),
              SwitchListTile(
                title: const Text('系統更新'),
                subtitle: Text('接收系統維護和更新通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.systemUpdate,
                onChanged: (v) => _updateSettings(context, settings.copyWith(systemUpdate: v)),
                activeColor: theme.colorScheme.primary,
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
