import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/models/user_model.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  // Available regions for subscription
  static const List<String> _regions = ['Taipei', 'Taichung', 'Kaohsiung'];

  // Available interests for subscription
  static const List<String> _interests = ['Sports', 'Music', 'Food', 'Travel', 'Movie', 'Tech', 'Art'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          _buildSectionTitle(context, '主題訂閱 - 地區'),
          ..._regions.map((region) {
            final topic = NotificationService.getRegionTopic(region);
            final isSubscribed = user.subscribedTopics.contains(topic);
            return _buildTopicTile(context, region, topic, isSubscribed, authProvider);
          }),

          const Divider(),
          _buildSectionTitle(context, '主題訂閱 - 興趣'),
          ..._interests.map((interest) {
            final topic = NotificationService.getInterestTopic(interest);
            final isSubscribed = user.subscribedTopics.contains(topic);
            return _buildTopicTile(context, interest, topic, isSubscribed, authProvider);
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

  Widget _buildTopicTile(
    BuildContext context,
    String title,
    String topic,
    bool isSubscribed,
    AuthProvider authProvider,
  ) {
    final theme = Theme.of(context);
    final notificationService = NotificationService();

    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        isSubscribed ? '已訂閱' : '未訂閱',
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      ),
      value: isSubscribed,
      onChanged: (bool value) async {
        final currentUser = authProvider.userModel;
        if (currentUser == null) return;

        List<String> currentTopics = List.from(currentUser.subscribedTopics);

        if (value) {
          // Subscribe
          if (!currentTopics.contains(topic)) {
            currentTopics.add(topic);
            await notificationService.subscribeToTopic(topic);
          }
        } else {
          // Unsubscribe
          if (currentTopics.contains(topic)) {
            currentTopics.remove(topic);
            await notificationService.unsubscribeFromTopic(topic);
          }
        }

        // Update User Model in Firestore
        await authProvider.updateUserData({
          'subscribedTopics': currentTopics,
        });
      },
      activeColor: theme.colorScheme.primary,
    );
  }
}





