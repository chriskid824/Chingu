import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isUpdating = false;

  Future<void> _updatePreference(BuildContext context, String key, bool value) async {
    setState(() => _isUpdating = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentPrefs = authProvider.userModel?.notificationPreferences ?? const NotificationPreferences();

      NotificationPreferences newPrefs;
      switch (key) {
        case 'enablePushNotifications':
          newPrefs = currentPrefs.copyWith(enablePushNotifications: value);
          break;
        case 'newMatch':
          newPrefs = currentPrefs.copyWith(newMatch: value);
          break;
        case 'matchSuccess':
          newPrefs = currentPrefs.copyWith(matchSuccess: value);
          break;
        case 'newMessage':
          newPrefs = currentPrefs.copyWith(newMessage: value);
          break;
        case 'eventReminder':
          newPrefs = currentPrefs.copyWith(eventReminder: value);
          break;
        case 'eventChanges':
          newPrefs = currentPrefs.copyWith(eventChanges: value);
          break;
        case 'promotions':
          newPrefs = currentPrefs.copyWith(promotions: value);
          break;
        case 'newsletter':
          newPrefs = currentPrefs.copyWith(newsletter: value);
          break;
        default:
          newPrefs = currentPrefs;
      }

      final success = await authProvider.updateUserData({
        'notificationPreferences': newPrefs.toMap(),
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.errorMessage ?? '更新失敗')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    // Listen to AuthProvider to get latest user data
    final authProvider = Provider.of<AuthProvider>(context);
    final prefs = authProvider.userModel?.notificationPreferences ?? const NotificationPreferences();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: _isUpdating
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.enablePushNotifications,
            onChanged: (v) => _updatePreference(context, 'enablePushNotifications', v),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.newMatch,
            onChanged: (v) => _updatePreference(context, 'newMatch', v),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.matchSuccess,
            onChanged: (v) => _updatePreference(context, 'matchSuccess', v),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.newMessage,
            onChanged: (v) => _updatePreference(context, 'newMessage', v),
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
            title: const Text('預約提醒'),
            subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.eventReminder,
            onChanged: (v) => _updatePreference(context, 'eventReminder', v),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.eventChanges,
            onChanged: (v) => _updatePreference(context, 'eventChanges', v),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.promotions,
            onChanged: (v) => _updatePreference(context, 'promotions', v),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: prefs.newsletter,
            onChanged: (v) => _updatePreference(context, 'newsletter', v),
            activeColor: theme.colorScheme.primary,
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
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
      ),
    );
  }
}
