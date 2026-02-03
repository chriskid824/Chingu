import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final chinguTheme = theme.extension<ChinguTheme>(); // Unused

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        // Handle loading or null user state
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
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: true, // TODO: Integrate with system permission check or global toggle
                onChanged: (v) {
                  // Optional: Implement global disable logic or open system settings
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('配對通知'),
                subtitle: Text('接收新配對與配對成功通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMatches,
                onChanged: (v) => authProvider.updateUserData({'notificationMatches': v}),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMessages,
                onChanged: (v) => authProvider.updateUserData({'notificationMessages': v}),
                activeColor: theme.colorScheme.primary,
              ),
              ListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text(user.showMessagePreview ? '總是顯示' : '從不顯示', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
                title: const Text('活動通知'),
                subtitle: Text('接收預約提醒與變更通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationEvents,
                onChanged: (v) => authProvider.updateUserData({'notificationEvents': v}),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('行銷通知'),
                subtitle: Text('接收優惠與電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMarketing,
                onChanged: (v) => authProvider.updateUserData({'notificationMarketing': v}),
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
