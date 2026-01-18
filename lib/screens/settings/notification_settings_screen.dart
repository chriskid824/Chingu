import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';

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

          final settings = user.notificationSettings;

          return ListView(
            children: [
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.pushEnabled,
                onChanged: (v) => _updateSettings(context, settings.copyWith(pushEnabled: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.newMatch,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(newMatch: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.matchSuccess,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(matchSuccess: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.newMessage,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(newMessage: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text(settings.showMessagePreview ? '總是顯示' : '隱藏內容', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.showMessagePreview,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(showMessagePreview: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              // Optional: Keep the preview link if needed, but the requirement was integration.
              // The previous code had a ListTile for preview. I'll keep it as a button to test preview if desired,
              // but the setting "Show Preview" is now a toggle as per model.
              ListTile(
                title: const Text('測試通知預覽'),
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
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.eventReminder,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(eventReminder: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.eventChanges,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(eventChanges: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.marketingPromotion,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(marketingPromotion: v)) : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.marketingNewsletter,
                onChanged: settings.pushEnabled ? (v) => _updateSettings(context, settings.copyWith(marketingNewsletter: v)) : null,
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

  void _updateSettings(BuildContext context, NotificationSettingsModel newSettings) {
    Provider.of<AuthProvider>(context, listen: false).updateUserData({
      'notificationSettings': newSettings.toMap(),
    });
  }
}
