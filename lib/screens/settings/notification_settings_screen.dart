import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('通知設定', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildNotificationSwitch(
                context,
                title: '新配對通知',
                subtitle: '當您有新的配對成功時接收通知',
                value: user.newMatchNotification,
                onChanged: (value) {
                  authProvider.updateUserData({'newMatchNotification': value});
                },
              ),
              const Divider(),
              _buildNotificationSwitch(
                context,
                title: '新訊息通知',
                subtitle: '當您收到新訊息時接收通知',
                value: user.newMessageNotification,
                onChanged: (value) {
                  authProvider.updateUserData({'newMessageNotification': value});
                },
              ),
              const Divider(),
              _buildNotificationSwitch(
                context,
                title: '活動更新通知',
                subtitle: '接收關於您參加活動的更新和提醒',
                value: user.eventUpdateNotification,
                onChanged: (value) {
                  authProvider.updateUserData({'eventUpdateNotification': value});
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationSwitch(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
