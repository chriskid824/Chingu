import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // 預設值
  bool _pushEnabled = true;
  bool _newMatch = true;
  bool _matchSuccess = true;
  bool _newMessage = true;
  bool _eventReminder = true;
  bool _eventChange = true;
  bool _promotions = false;
  bool _newsletter = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('notif_push') ?? true;
      _newMatch = prefs.getBool('notif_new_match') ?? true;
      _matchSuccess = prefs.getBool('notif_match_success') ?? true;
      _newMessage = prefs.getBool('notif_new_message') ?? true;
      _eventReminder = prefs.getBool('notif_event_reminder') ?? true;
      _eventChange = prefs.getBool('notif_event_change') ?? true;
      _promotions = prefs.getBool('notif_promotions') ?? false;
      _newsletter = prefs.getBool('notif_newsletter') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

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
      body: ListView(
        children: [
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _pushEnabled,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              _saveSetting('notif_push', v);
            },
            activeColor: theme.colorScheme.primary,
          ),
          ListTile(
            title: const Text('主題訂閱'),
            subtitle: Text('設定地區與興趣主題通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.topicSubscription);
            },
          ),
          const Divider(),
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _newMatch && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _newMatch = v);
              _saveSetting('notif_new_match', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _matchSuccess && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _matchSuccess = v);
              _saveSetting('notif_match_success', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _newMessage && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _newMessage = v);
              _saveSetting('notif_new_message', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '活動通知'),
          SwitchListTile(
            title: const Text('預約提醒'),
            subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _eventReminder && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _eventReminder = v);
              _saveSetting('notif_event_reminder', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _eventChange && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _eventChange = v);
              _saveSetting('notif_event_change', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _promotions && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _promotions = v);
              _saveSetting('notif_promotions', v);
            } : null,
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: _newsletter && _pushEnabled,
            onChanged: _pushEnabled ? (v) {
              setState(() => _newsletter = v);
              _saveSetting('notif_newsletter', v);
            } : null,
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
