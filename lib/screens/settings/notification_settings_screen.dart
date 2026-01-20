import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          '通知設定',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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

          return Column(
            children: [
              if (authProvider.isLoading)
                LinearProgressIndicator(
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                ),
              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle(context, '配對通知'),
                    SwitchListTile(
                      title: const Text('配對相關通知'),
                      subtitle: Text(
                        '接收新配對與配對成功的通知',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      value: settings.notifyMatch,
                      onChanged: authProvider.isLoading
                          ? null
                          : (val) => _updateSettings(context, authProvider, settings.copyWith(notifyMatch: val)),
                      activeColor: theme.colorScheme.primary,
                    ),
                    const Divider(),

                    _buildSectionTitle(context, '訊息通知'),
                    SwitchListTile(
                      title: const Text('新訊息'),
                      subtitle: Text(
                        '收到新訊息時通知',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      value: settings.notifyMessage,
                      onChanged: authProvider.isLoading
                          ? null
                          : (val) => _updateSettings(context, authProvider, settings.copyWith(notifyMessage: val)),
                      activeColor: theme.colorScheme.primary,
                    ),
                    const Divider(),

                    _buildSectionTitle(context, '活動通知'),
                    SwitchListTile(
                      title: const Text('活動相關通知'),
                      subtitle: Text(
                        '接收預約提醒與變更通知',
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      value: settings.notifyEvent,
                      onChanged: authProvider.isLoading
                          ? null
                          : (val) => _updateSettings(context, authProvider, settings.copyWith(notifyEvent: val)),
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                ),
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

  void _updateSettings(BuildContext context, AuthProvider provider, NotificationSettings newSettings) {
    provider.updateUserData({
      'notificationSettings': newSettings.toMap(),
    });
  }
}
