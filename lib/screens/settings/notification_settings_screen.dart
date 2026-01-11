import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  void _updateSetting(BuildContext context, AuthProvider authProvider, String key, bool value) {
    final currentSettings = Map<String, bool>.from(authProvider.userModel?.notificationSettings ?? {});
    currentSettings[key] = value;
    authProvider.updateUserData({'notificationSettings': currentSettings});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final settings = authProvider.userModel?.notificationSettings ?? {};

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
                value: settings['pushEnabled'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'pushEnabled', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['matchNew'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'matchNew', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['matchSuccess'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'matchSuccess', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['messageNew'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'messageNew', v),
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
                title: const Text('預約提醒 (1天前)'),
                subtitle: Text('晚餐前 1 天提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['eventReminder1d'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'eventReminder1d', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約提醒 (1小時前)'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['eventReminder1h'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'eventReminder1h', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['eventUpdate'] ?? true,
                onChanged: (v) => _updateSetting(context, authProvider, 'eventUpdate', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['marketingPromotions'] ?? false,
                onChanged: (v) => _updateSetting(context, authProvider, 'marketingPromotions', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings['marketingNewsletter'] ?? false,
                onChanged: (v) => _updateSetting(context, authProvider, 'marketingNewsletter', v),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        );
      },
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





