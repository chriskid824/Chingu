import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

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

          final subscribedTopics = user.subscribedTopics;

          return ListView(
            children: [
              _buildSectionTitle(context, '主題訂閱'),
              _buildTopicSection(
                context,
                '地區訂閱',
                [
                  {'id': 'region_taipei', 'name': '台北'},
                  {'id': 'region_taichung', 'name': '台中'},
                  {'id': 'region_kaohsiung', 'name': '高雄'},
                ],
                subscribedTopics,
                authProvider,
              ),
              const SizedBox(height: 8),
              _buildTopicSection(
                context,
                '興趣訂閱',
                [
                  {'id': 'interest_leisure', 'name': '休閒娛樂'},
                  {'id': 'interest_lifestyle', 'name': '生活風格'},
                  {'id': 'interest_sports', 'name': '運動健身'},
                  {'id': 'interest_arts', 'name': '藝術創意'},
                  {'id': 'interest_tech', 'name': '科技與知識'},
                ],
                subscribedTopics,
                authProvider,
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

              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: false,
                onChanged: (v) {},
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: false,
                onChanged: (v) {},
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

  Widget _buildTopicSection(
    BuildContext context,
    String title,
    List<Map<String, String>> items,
    List<String> currentSubscriptions,
    AuthProvider authProvider,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            )
          ),
        ),
        ...items.map((item) {
          final topicId = item['id']!;
          final topicName = item['name']!;
          final isSubscribed = currentSubscriptions.contains(topicId);

          return SwitchListTile(
            title: Text(topicName),
            value: isSubscribed,
            activeColor: theme.colorScheme.primary,
            dense: true,
            onChanged: (bool value) async {
              final newSubscriptions = List<String>.from(currentSubscriptions);
              if (value) {
                newSubscriptions.add(topicId);
                await RichNotificationService().subscribeToTopic(topicId);
              } else {
                newSubscriptions.remove(topicId);
                await RichNotificationService().unsubscribeFromTopic(topicId);
              }

              await authProvider.updateUserData({
                'subscribedTopics': newSubscriptions,
              });
            },
          );
        }),
      ],
    );
  }
}
