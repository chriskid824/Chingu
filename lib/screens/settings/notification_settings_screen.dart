import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  void _updateSetting(BuildContext context, String key, bool value) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final newSettings = Map<String, bool>.from(user.notificationSettings);
    newSettings[key] = value;

    authProvider.updateUserData({
      'notificationSettings': newSettings
    });
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
          final pushEnabled = settings['pushEnabled'] ?? true;
          final matchNew = settings['matchNew'] ?? true;
          final matchSuccess = settings['matchSuccess'] ?? true;
          final messageNew = settings['messageNew'] ?? true;
          final messagePreview = settings['messagePreview'] ?? true;
          final eventReminder = settings['eventReminder'] ?? true;
          final eventUpdate = settings['eventUpdate'] ?? true;
          final marketingPromo = settings['marketingPromo'] ?? false;
          final marketingNewsletter = settings['marketingNewsletter'] ?? false;

          return ListView(
            children: [
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: pushEnabled,
                onChanged: (v) => _updateSetting(context, 'pushEnabled', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: matchNew,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'matchNew', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: matchSuccess,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'matchSuccess', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: messageNew,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'messageNew', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              ListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text(messagePreview ? '總是顯示' : '從不顯示', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                enabled: pushEnabled,
                onTap: pushEnabled ? () {
                  Navigator.pushNamed(context, AppRoutes.notificationPreview);
                } : null,
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: eventReminder,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'eventReminder', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: eventUpdate,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'eventUpdate', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: marketingPromo,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'marketingPromo', v) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: marketingNewsletter,
                onChanged: pushEnabled ? (v) => _updateSetting(context, 'marketingNewsletter', v) : null,
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





