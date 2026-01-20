import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/notification_settings_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final List<Map<String, String>> _regions = [
    {'id': 'taipei', 'label': '台北'},
    {'id': 'taichung', 'label': '台中'},
    {'id': 'kaohsiung', 'label': '高雄'},
  ];

  // 簡化的興趣列表，實際應用中應與 InterestsSelectionScreen 共享數據
  final List<String> _availableInterests = [
    '電影', '音樂', '遊戲', '閱讀', '動漫', '桌遊',
    '美食', '旅遊', '咖啡', '寵物', '烹飪', '品酒', '購物',
    '籃球', '健身', '跑步', '游泳', '瑜珈', '爬山', '羽球',
    '攝影', '繪畫', '設計', '手作', '寫作',
    '科技', '程式設計', '投資理財', '語言學習'
  ];

  Future<void> _updateSettings(
    BuildContext context,
    NotificationSettings currentSettings,
    NotificationSettings newSettings
  ) async {
    final provider = context.read<AuthProvider>();
    await provider.updateNotificationSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // 使用 Consumer 監聽 AuthProvider 變化
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final settings = authProvider.userModel?.notificationSettings ?? const NotificationSettings();

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
              _buildSectionTitle(context, '主題訂閱'),
              ExpansionTile(
                title: const Text('地區訂閱'),
                subtitle: Text(
                  settings.subscribedRegions.isEmpty
                    ? '尚未訂閱地區'
                    : '已訂閱 ${settings.subscribedRegions.length} 個地區',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                children: _regions.map((region) {
                  final isSelected = settings.subscribedRegions.contains(region['id']);
                  return CheckboxListTile(
                    title: Text(region['label']!),
                    value: isSelected,
                    activeColor: theme.colorScheme.primary,
                    onChanged: (bool? value) {
                      final currentRegions = List<String>.from(settings.subscribedRegions);
                      if (value == true) {
                        currentRegions.add(region['id']!);
                      } else {
                        currentRegions.remove(region['id']!);
                      }
                      _updateSettings(
                        context,
                        settings,
                        settings.copyWith(subscribedRegions: currentRegions)
                      );
                    },
                  );
                }).toList(),
              ),
              ExpansionTile(
                title: const Text('興趣訂閱'),
                subtitle: Text(
                  settings.subscribedInterests.isEmpty
                    ? '尚未訂閱興趣'
                    : '已訂閱 ${settings.subscribedInterests.length} 個興趣',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _availableInterests.map((interest) {
                        final isSelected = settings.subscribedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                          checkmarkColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (bool value) {
                            final currentInterests = List<String>.from(settings.subscribedInterests);
                            if (value) {
                              currentInterests.add(interest);
                            } else {
                              currentInterests.remove(interest);
                            }
                            _updateSettings(
                              context,
                              settings,
                              settings.copyWith(subscribedInterests: currentInterests)
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              const Divider(),
              _buildSectionTitle(context, '推播通知'),
              SwitchListTile(
                title: const Text('啟用推播通知'),
                subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyPush,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyPush: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('新配對'),
                subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewMatch,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyNewMatch: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('配對成功'),
                subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyMatchSuccess,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyMatchSuccess: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('新訊息'),
                subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewMessage,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyNewMessage: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('顯示訊息預覽'),
                subtitle: Text('總是顯示', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.showMessagePreview,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(showMessagePreview: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('預約提醒'),
                subtitle: Text('晚餐前 1 小時提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyEventReminder,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyEventReminder: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('預約變更'),
                subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyEventChange,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyEventChange: v)),
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '行銷通知'),
              SwitchListTile(
                title: const Text('優惠活動'),
                subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyMarketing,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyMarketing: v)),
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('電子報'),
                subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: settings.notifyNewsletter,
                onChanged: (v) => _updateSettings(context, settings, settings.copyWith(notifyNewsletter: v)),
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
