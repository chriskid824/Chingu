import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';

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

          final settings = user.notificationSettings;

          return ListView(
            children: [
              _buildSectionTitle(context, '一般通知'),
              SwitchListTile(
                title: const Text('配對通知'),
                subtitle: Text('當有人喜歡您或配對成功時通知',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.matchNotifications,
                onChanged: (val) {
                  _updateSettings(context, authProvider, settings.copyWith(matchNotifications: val));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('訊息通知'),
                subtitle: Text('收到新訊息時通知',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.messageNotifications,
                onChanged: (val) {
                  _updateSettings(context, authProvider, settings.copyWith(messageNotifications: val));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('活動通知'),
                subtitle: Text('晚餐提醒與活動變更通知',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.eventNotifications,
                onChanged: (val) {
                  _updateSettings(context, authProvider, settings.copyWith(eventNotifications: val));
                },
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

  void _updateSettings(BuildContext context, AuthProvider authProvider, NotificationSettingsModel newSettings) {
    authProvider.updateUserData({
      'notificationSettings': newSettings.toMap(),
    });
  }
}
