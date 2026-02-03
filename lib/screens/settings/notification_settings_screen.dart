import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                subtitle: Text(
                  '當有人喜歡您或配對成功時通知',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))
                ),
                value: user.notificationMatches,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notificationMatches': value});
                },
              ),
              const Divider(),

              SwitchListTile(
                title: const Text('訊息通知'),
                subtitle: Text(
                  '收到新訊息時通知',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))
                ),
                value: user.notificationMessages,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notificationMessages': value});
                },
              ),
              const Divider(),

              SwitchListTile(
                title: const Text('活動通知'),
                subtitle: Text(
                  '晚餐活動相關通知',
                  style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))
                ),
                value: user.notificationEvents,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notificationEvents': value});
                },
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
