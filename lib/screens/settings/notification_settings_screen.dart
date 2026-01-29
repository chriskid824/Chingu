import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Helper to update settings
  Future<void> _updateSetting(BuildContext context, String key, bool value) async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.userModel;
    if (currentUser == null) return;

    final currentSettings = Map<String, bool>.from(currentUser.notificationSettings);
    currentSettings[key] = value;

    await authProvider.updateUserData({
      'notificationSettings': currentSettings,
    });
  }
  
  // Helper to get setting value safely
  bool _getSetting(UserModel? user, String key, {bool defaultValue = true}) {
    if (user == null) return defaultValue;
    return user.notificationSettings[key] ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use Consumer to rebuild when user data changes
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;

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
                value: _getSetting(user, 'push_enabled'),
                onChanged: (v) => _updateSetting(context, 'push_enabled', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'match_new'),
                onChanged: (v) => _updateSetting(context, 'match_new', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'match_success'),
                onChanged: (v) => _updateSetting(context, 'match_success', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'message_new'),
                onChanged: (v) => _updateSetting(context, 'message_new', v),
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
                value: _getSetting(user, 'event_reminder'),
                onChanged: (v) => _updateSetting(context, 'event_reminder', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'event_change'),
                onChanged: (v) => _updateSetting(context, 'event_change', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'marketing_promo', defaultValue: false),
                onChanged: (v) => _updateSetting(context, 'marketing_promo', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: _getSetting(user, 'marketing_newsletter', defaultValue: false),
                onChanged: (v) => _updateSetting(context, 'marketing_newsletter', v),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        );
      }
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
