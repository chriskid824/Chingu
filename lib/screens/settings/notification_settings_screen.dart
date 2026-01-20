import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  void _updateSettings(BuildContext context, NotificationSettings newSettings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.updateUserData({
      'notificationSettings': newSettings.toMap(),
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final settings = authProvider.userModel?.notificationSettings ?? const NotificationSettings();
        final masterSwitch = settings.enablePushNotifications;

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
                value: settings.enablePushNotifications,
                onChanged: (v) {
                  _updateSettings(context, settings.copyWith(enablePushNotifications: v));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewMatch,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyNewMatch: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyMatchSuccess,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyMatchSuccess: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewMessage,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyNewMessage: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text('在通知中顯示訊息內容', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.showMessagePreview,
                onChanged: masterSwitch ? (v) {
                   _updateSettings(context, settings.copyWith(showMessagePreview: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
               // Removed redundant navigation tile as we have a direct switch now based on requirement or keep it if it's for customizing preview style.
               // Based on field 'showMessagePreview', it's a bool. The previous code had a navigation to 'notificationPreview'.
               // I will keep the navigation item as an extra option but also add the switch for the boolean preference.
               // Actually, looking at the previous code, it was just a ListTile navigating to another screen.
               // If the user wants to integrate preference, "Show Message Preview" is typically a toggle.
               // I replaced the ListTile with a SwitchListTile to match the boolean field.
               // If the 'notificationPreview' screen is for visual testing, I can keep it but maybe under a different name or separate item?
               // The original UI had "顯示訊息預覽" as a navigation item. I'll convert it to a switch as per the model.
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyAppointmentReminder,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyAppointmentReminder: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyAppointmentChange,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyAppointmentChange: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyPromotions,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyPromotions: v));
                } : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewsletter,
                onChanged: masterSwitch ? (v) {
                  _updateSettings(context, settings.copyWith(notifyNewsletter: v));
                } : null,
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





