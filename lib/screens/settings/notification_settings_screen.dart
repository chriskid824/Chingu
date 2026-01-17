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
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final prefs = user.notificationPreferences;

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
                subtitle: Text('接收應用程式的推播通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.enablePush,
                onChanged: (val) => _updatePreferences(
                    context, authProvider, prefs.copyWith(enablePush: val)),
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
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(
                        context, authProvider, prefs.copyWith(newMatch: val))
                    : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.matchSuccess,
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(matchSuccess: val))
                    : null,
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
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(
                        context, authProvider, prefs.copyWith(newMessage: val))
                    : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text(prefs.showMessagePreview ? '總是顯示' : '隱藏內容',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.showMessagePreview,
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(showMessagePreview: val))
                    : null,
                activeColor: theme.colorScheme.primary,
              ),
               // 保留預覽頁面入口，如果需要查看預覽效果
              ListTile(
                title: const Text('預覽通知樣式'),
                 subtitle: Text('查看通知在裝置上的顯示效果',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
                subtitle: Text('晚餐前 1 小時提醒',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.eventReminder,
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(eventReminder: val))
                    : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.eventChange,
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(eventChange: val))
                    : null,
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
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(marketingPromo: val))
                    : null,
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs.marketingNewsletter,
                onChanged: prefs.enablePush
                    ? (val) => _updatePreferences(context, authProvider,
                        prefs.copyWith(marketingNewsletter: val))
                    : null,
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

  Future<void> _updatePreferences(BuildContext context,
      AuthProvider authProvider, NotificationPreferences newPrefs) async {
    final user = authProvider.userModel;
    if (user == null) return;

    final updatedUser = user.copyWith(notificationPreferences: newPrefs);

    // AuthProvider.updateUserData 只需要傳遞要更新的欄位
    // 這裡我們傳遞整個 notificationPreferences 物件的 Map
    final success = await authProvider.updateUserData({
      'notificationPreferences': newPrefs.toMap(),
    });

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新設定失敗，請稍後再試')),
      );
    }
  }
}
