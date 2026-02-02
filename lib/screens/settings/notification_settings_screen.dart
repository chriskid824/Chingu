import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
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
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('接收配對通知'),
            subtitle: Text('當有人喜歡您或配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: user.notificationMatches,
            onChanged: (v) {
              authProvider.updateUserData({'notificationMatches': v});
            },
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('接收訊息通知'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: user.notificationMessages,
            onChanged: (v) {
              authProvider.updateUserData({'notificationMessages': v});
            },
          ),
          SwitchListTile(
            title: const Text('顯示訊息預覽'),
            subtitle: Text('在通知中顯示訊息內容', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: user.showMessagePreview,
            onChanged: (v) {
              authProvider.updateUserData({'showMessagePreview': v});
            },
          ),
          const Divider(),
          _buildSectionTitle(context, '活動通知'),
          SwitchListTile(
            title: const Text('接收活動通知'),
            subtitle: Text('接收預約提醒與變更通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: user.notificationEvents,
            onChanged: (v) {
              authProvider.updateUserData({'notificationEvents': v});
            },
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
