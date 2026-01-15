import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/topic_subscription_service.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);

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
          _buildTopicSubscriptions(context, authProvider),
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

  Widget _buildTopicSubscriptions(BuildContext context, AuthProvider authProvider) {
    final theme = Theme.of(context);
    final user = authProvider.userModel;

    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '地區訂閱'),
        ...['Taipei', 'Taichung', 'Kaohsiung'].map((region) {
          final isSubscribed = user.subscribedRegions.contains(region);
          return SwitchListTile(
            title: Text(_getRegionDisplayName(region)),
            subtitle: Text('訂閱${_getRegionDisplayName(region)}的相關通知',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: isSubscribed,
            activeColor: theme.colorScheme.primary,
            onChanged: (val) async {
              await TopicSubscriptionService().updateRegionSubscription(user.uid, region, val);
              await authProvider.refreshUserData();
            },
          );
        }),

        if (user.interests.isNotEmpty) ...[
          const Divider(),
          _buildSectionTitle(context, '興趣訂閱'),
          ...user.interests.map((interest) {
            final isSubscribed = user.subscribedInterests.contains(interest);
            return SwitchListTile(
              title: Text(interest),
              subtitle: Text('訂閱關於$interest的通知',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
              value: isSubscribed,
              activeColor: theme.colorScheme.primary,
              onChanged: (val) async {
                await TopicSubscriptionService().updateInterestSubscription(user.uid, interest, val);
                await authProvider.refreshUserData();
              },
            );
          }),
        ]
      ],
    );
  }

  String _getRegionDisplayName(String region) {
     switch(region.toLowerCase()) {
         case 'taipei': return '台北';
         case 'taichung': return '台中';
         case 'kaohsiung': return '高雄';
         default: return region;
     }
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





