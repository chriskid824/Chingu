import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/firestore_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = true;
  
  // Settings
  bool _pushEnabled = true;
  bool _matchEnabled = true;
  bool _messageEnabled = true;
  bool _eventEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Use addPostFrameCallback to safely access context/Provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = Provider.of<AuthProvider>(context, listen: false).uid;
      if (uid == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        final settings = await _firestoreService.getNotificationSettings(uid);
        if (settings != null) {
          setState(() {
            _pushEnabled = settings['push_enabled'] ?? true;
            _matchEnabled = settings['match_enabled'] ?? true;
            _messageEnabled = settings['message_enabled'] ?? true;
            _eventEnabled = settings['event_enabled'] ?? true;
          });
        }
      } catch (e) {
        debugPrint('Load settings error: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final uid = Provider.of<AuthProvider>(context, listen: false).uid;
    if (uid == null) return;

    // Update local state immediately for UI responsiveness
    setState(() {
      switch (key) {
        case 'push_enabled':
          _pushEnabled = value;
          break;
        case 'match_enabled':
          _matchEnabled = value;
          break;
        case 'message_enabled':
          _messageEnabled = value;
          break;
        case 'event_enabled':
          _eventEnabled = value;
          break;
      }
    });

    try {
      await _firestoreService.updateNotificationSettings(uid, {key: value});
    } catch (e) {
      debugPrint('Update setting error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設定更新失敗，請稍後再試')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Unused but kept for reference if needed later
    // final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, '推播通知'),
                SwitchListTile(
                  title: const Text('啟用推播通知'),
                  subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: _pushEnabled,
                  onChanged: (v) => _updateSetting('push_enabled', v),
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(),
                _buildSectionTitle(context, '配對通知'),
                SwitchListTile(
                  title: const Text('配對'),
                  subtitle: Text('當有人喜歡您或配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: _matchEnabled,
                  onChanged: _pushEnabled ? (v) => _updateSetting('match_enabled', v) : null,
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(),
                _buildSectionTitle(context, '訊息通知'),
                SwitchListTile(
                  title: const Text('訊息'),
                  subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: _messageEnabled,
                  onChanged: _pushEnabled ? (v) => _updateSetting('message_enabled', v) : null,
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
                  title: const Text('活動'),
                  subtitle: Text('預約提醒與變更通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  value: _eventEnabled,
                  onChanged: _pushEnabled ? (v) => _updateSetting('event_enabled', v) : null,
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
