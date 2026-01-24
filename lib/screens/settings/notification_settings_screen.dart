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

          return ListView(
            children: [
              _buildSectionTitle(context, '通知偏好'),
              SwitchListTile(
                title: const Text('配對通知'),
                subtitle: Text('接收新配對和配對成功通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.matchNotification,
                onChanged: (bool value) {
                  authProvider.updateUserData({'matchNotification': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('訊息通知'),
                subtitle: Text('接收新訊息通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.messageNotification,
                onChanged: (bool value) {
                  authProvider.updateUserData({'messageNotification': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('活動通知'),
                subtitle: Text('接收活動提醒和變更通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.eventNotification,
                onChanged: (bool value) {
                  authProvider.updateUserData({'eventNotification': value});
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
}
