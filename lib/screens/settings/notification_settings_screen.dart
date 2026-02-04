import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_preferences.dart';

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

          final prefs = user.notificationPreferences;

          return ListView(
            children: [
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('配對更新'),
                subtitle: Text('接收新配對和配對成功的通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.matchEnabled,
                onChanged: (bool value) {
                  _updatePreferences(context, authProvider, prefs.copyWith(matchEnabled: value));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('接收來自配對對象的新訊息通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.messageEnabled,
                onChanged: (bool value) {
                  _updatePreferences(context, authProvider, prefs.copyWith(messageEnabled: value));
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('活動更新'),
                subtitle: Text('接收活動提醒和變更通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.eventEnabled,
                onChanged: (bool value) {
                  _updatePreferences(context, authProvider, prefs.copyWith(eventEnabled: value));
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _updatePreferences(BuildContext context, AuthProvider authProvider, NotificationPreferences newPrefs) async {
    try {
      await authProvider.updateUserData({
        'notificationPreferences': newPrefs.toMap(),
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新設定失敗: $e')),
        );
      }
    }
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
