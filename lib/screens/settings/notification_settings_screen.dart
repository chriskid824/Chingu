import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_preferences_model.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.userModel;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final prefs = user.notificationPreferences;

          void updatePrefs(NotificationPreferences newPrefs) {
            auth.updateUserData({'notificationPreferences': newPrefs.toMap()});
          }

          return ListView(
            children: [
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.pushEnabled,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(pushEnabled: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.newMatch,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(newMatch: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.matchSuccess,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(matchSuccess: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.newMessage,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(newMessage: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text(prefs.showPreview ? '總是顯示' : '隱藏內容',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.showPreview,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(showPreview: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.eventReminder,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(eventReminder: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.eventChange,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(eventChange: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.marketingPromo,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(marketingPromo: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.marketingNewsletter,
                onChanged: (v) =>
                    updatePrefs(prefs.copyWith(marketingNewsletter: v)),
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





