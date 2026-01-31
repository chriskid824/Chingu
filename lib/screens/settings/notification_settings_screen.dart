import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/constants/notification_topics.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final chinguTheme = theme.extension<ChinguTheme>(); // Unused for now

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final userModel = authProvider.userModel;

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

              _buildSectionTitle(context, '主題訂閱'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text('地區訂閱', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ),
              ...NotificationTopics.regions.map((region) {
                final isSubscribed = userModel?.subscribedRegions.contains(region) ?? false;
                return CheckboxListTile(
                  title: Text(NotificationTopics.regionDisplayNames[region] ?? region),
                  value: isSubscribed,
                  onChanged: (bool? value) {
                    if (value == null) return;
                    final currentRegions = List<String>.from(userModel?.subscribedRegions ?? []);
                    if (value) {
                      currentRegions.add(region);
                    } else {
                      currentRegions.remove(region);
                    }
                    authProvider.updateNotificationSubscriptions(regions: currentRegions);
                  },
                  activeColor: theme.colorScheme.primary,
                  dense: true,
                );
              }),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('興趣訂閱', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: NotificationTopics.interestCategories.map((interest) {
                    final isSubscribed = userModel?.subscribedInterests.contains(interest) ?? false;
                    final displayName = NotificationTopics.interestDisplayNames[interest] ?? interest;

                    return FilterChip(
                      label: Text(displayName),
                      selected: isSubscribed,
                      onSelected: (bool selected) {
                        final currentInterests = List<String>.from(userModel?.subscribedInterests ?? []);
                        if (selected) {
                          currentInterests.add(interest);
                        } else {
                          currentInterests.remove(interest);
                        }
                        authProvider.updateNotificationSubscriptions(interests: currentInterests);
                      },
                      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSubscribed ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        fontWeight: isSubscribed ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSubscribed ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
                ),
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
}
