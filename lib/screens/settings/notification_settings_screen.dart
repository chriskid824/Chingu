import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _isLoading = false;

  Future<void> _updatePreference(
    BuildContext context,
    String key,
    bool value,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userModel = authProvider.userModel;

    if (userModel == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. 更新本地 Model 狀態 (Optimistic UI)
      final newPreferences = Map<String, bool>.from(userModel.notificationPreferences);
      newPreferences[key] = value;

      // 2. 更新 Firestore
      final success = await authProvider.updateUserData({
        'notificationPreferences': newPreferences,
      });

      if (!success) {
        throw Exception('更新失敗');
      }

      // 3. 處理 Topic 訂閱
      if (key == 'marketing') {
        if (value) {
          await _firebaseMessaging.subscribeToTopic('marketing');
        } else {
          await _firebaseMessaging.unsubscribeFromTopic('marketing');
        }
      } else if (key == 'newsletter') {
        if (value) {
          await _firebaseMessaging.subscribeToTopic('newsletter');
        } else {
          await _firebaseMessaging.unsubscribeFromTopic('newsletter');
        }
      } else if (key == 'appUpdates') {
        if (value) {
          await _firebaseMessaging.subscribeToTopic('app_updates');
        } else {
          await _firebaseMessaging.unsubscribeFromTopic('app_updates');
        }
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定更新失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // final chinguTheme = theme.extension<ChinguTheme>(); // Unused for now

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surface,
                ),
              )
            : null,
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
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['newMatch'] ?? true,
                onChanged: (v) => _updatePreference(context, 'newMatch', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['matchSuccess'] ?? true,
                onChanged: (v) => _updatePreference(context, 'matchSuccess', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['newMessage'] ?? true,
                onChanged: (v) => _updatePreference(context, 'newMessage', v),
                activeColor: theme.colorScheme.primary,
              ),
              ListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text('總是顯示',
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
                value: prefs['eventReminder'] ?? true,
                onChanged: (v) =>
                    _updatePreference(context, 'eventReminder', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['eventChange'] ?? true,
                onChanged: (v) => _updatePreference(context, 'eventChange', v),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['marketing'] ?? false,
                onChanged: (v) => _updatePreference(context, 'marketing', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['newsletter'] ?? false,
                onChanged: (v) => _updatePreference(context, 'newsletter', v),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('應用程式更新'),
                subtitle: Text('接收新功能和更新通知',
                    style: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: prefs['appUpdates'] ?? true,
                onChanged: (v) => _updatePreference(context, 'appUpdates', v),
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
