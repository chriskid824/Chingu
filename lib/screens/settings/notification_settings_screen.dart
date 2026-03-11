import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';
import 'package:chingu/services/notification_preferences_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationSettingsModel _settings;
  bool _isLoading = false;
  final NotificationPreferencesService _preferencesService = NotificationPreferencesService();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;
    _settings = user?.notificationSettings ?? const NotificationSettingsModel();
  }

  Future<void> _updateSettings(NotificationSettingsModel newSettings) async {
    // Optimistically update local state
    setState(() {
      _settings = newSettings;
    });

    // Debouncing could be added here, but for now we save immediately
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        // Save using service (which handles syncing topics)
        await _preferencesService.saveSettings(
          user.uid,
          newSettings,
          oldSettings: user.notificationSettings
        );

        // Refresh AuthProvider to reflect changes in app state
        if (mounted) {
           await context.read<AuthProvider>().refreshUserData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新設定失敗: $e')),
        );
        // Revert on failure
        final user = context.read<AuthProvider>().userModel;
        if (user != null) {
          setState(() {
            _settings = user.notificationSettings ?? const NotificationSettingsModel();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleRegion(String region, bool? value) {
    if (value == null) return;

    final currentRegions = List<String>.from(_settings.subscribedRegions);
    if (value) {
      if (!currentRegions.contains(region)) currentRegions.add(region);
    } else {
      currentRegions.remove(region);
    }

    _updateSettings(_settings.copyWith(subscribedRegions: currentRegions));
  }

  void _toggleInterest(String interest, bool? value) {
    if (value == null) return;

    final currentInterests = List<String>.from(_settings.subscribedInterests);
    if (value) {
      if (!currentInterests.contains(interest)) currentInterests.add(interest);
    } else {
      currentInterests.remove(interest);
    }

    _updateSettings(_settings.copyWith(subscribedInterests: currentInterests));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;
    final userInterests = user?.interests ?? [];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.pushEnabled,
            onChanged: (v) => _updateSettings(_settings.copyWith(pushEnabled: v)),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.newMatch,
            onChanged: (v) => _updateSettings(_settings.copyWith(newMatch: v)),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.matchSuccess,
            onChanged: (v) => _updateSettings(_settings.copyWith(matchSuccess: v)),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.newMessage,
            onChanged: (v) => _updateSettings(_settings.copyWith(newMessage: v)),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示訊息預覽'),
            subtitle: Text('在通知中顯示訊息內容', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.messagePreview,
            onChanged: (v) => _updateSettings(_settings.copyWith(messagePreview: v)),
            activeColor: theme.colorScheme.primary,
          ),
           ListTile(
            title: const Text('預覽測試'),
            subtitle: Text('點擊測試通知預覽效果', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
            value: _settings.eventReminder,
            onChanged: (v) => _updateSettings(_settings.copyWith(eventReminder: v)),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.eventChange,
            onChanged: (v) => _updateSettings(_settings.copyWith(eventChange: v)),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.promo,
            onChanged: (v) => _updateSettings(_settings.copyWith(promo: v)),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _settings.newsletter,
            onChanged: (v) => _updateSettings(_settings.copyWith(newsletter: v)),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '區域訂閱'),
          CheckboxListTile(
            title: const Text('台北 (Taipei)'),
            value: _settings.subscribedRegions.contains('taipei'),
            onChanged: (v) => _toggleRegion('taipei', v),
            activeColor: theme.colorScheme.primary,
          ),
          CheckboxListTile(
            title: const Text('台中 (Taichung)'),
            value: _settings.subscribedRegions.contains('taichung'),
            onChanged: (v) => _toggleRegion('taichung', v),
            activeColor: theme.colorScheme.primary,
          ),
          CheckboxListTile(
            title: const Text('高雄 (Kaohsiung)'),
            value: _settings.subscribedRegions.contains('kaohsiung'),
            onChanged: (v) => _toggleRegion('kaohsiung', v),
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '興趣主題訂閱'),
          if (userInterests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '請先在個人檔案中新增興趣，即可訂閱相關主題通知。',
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            )
          else
            ...userInterests.map((interest) => CheckboxListTile(
              title: Text(interest),
              value: _settings.subscribedInterests.contains(interest),
              onChanged: (v) => _toggleInterest(interest, v),
              activeColor: theme.colorScheme.primary,
            )),
          const SizedBox(height: 32),
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
