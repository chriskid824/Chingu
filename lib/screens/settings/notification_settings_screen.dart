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
    final chinguTheme = theme.extension<ChinguTheme>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;

        // Handling loading or no user state
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
                value: true, // This should ideally check system permissions
                onChanged: (v) {
                  // Usually redirects to system settings
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您或配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.newMatchNotification,
                onChanged: (v) {
                  authProvider.updateUserData({'newMatchNotification': v});
                },
                activeColor: theme.colorScheme.primary,
              ),
              // Removed redundant "Match Success" to simplify mapping
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.newMessageNotification,
                onChanged: (v) {
                  authProvider.updateUserData({'newMessageNotification': v});
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
                title: const Text('預約變更與提醒'),
                subtitle: Text('當預約有變更或即將開始時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.eventUpdateNotification,
                onChanged: (v) {
                  authProvider.updateUserData({'eventUpdateNotification': v});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷與主題'),
              SwitchListTile(
                title: const Text('優惠與興趣推送'),
                subtitle: Text('根據您的地區和興趣接收相關資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.marketingNotification,
                onChanged: (v) {
                  authProvider.updateUserData({'marketingNotification': v});
                },
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
