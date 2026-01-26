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

          return ListView(
            children: [
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('配對相關通知'),
                subtitle: Text('包含新配對、配對成功等通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMatchEnabled,
                onChanged: (v) {
                  authProvider.updateUserData({'notificationMatchEnabled': v});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息通知'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMessageEnabled,
                onChanged: (v) {
                  authProvider.updateUserData({'notificationMessageEnabled': v});
                },
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
                title: const Text('活動相關通知'),
                subtitle: Text('包含預約提醒、變更等通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationEventEnabled,
                onChanged: (v) {
                  authProvider.updateUserData({'notificationEventEnabled': v});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('行銷與優惠通知'),
                subtitle: Text('接收優惠活動與電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notificationMarketingEnabled,
                onChanged: (v) {
                  authProvider.updateUserData({'notificationMarketingEnabled': v});
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
