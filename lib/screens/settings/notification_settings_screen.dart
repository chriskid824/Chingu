import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _isInitialized = false;
  
  // Local state for topic subscriptions
  List<String> _selectedRegions = [];
  List<String> _selectedInterests = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userModel != null) {
        _selectedRegions = List.from(authProvider.userModel!.subscribedRegions);
        _selectedInterests = List.from(authProvider.userModel!.subscribedTopicInterests);
        _isInitialized = true;
      }
    }
  }

  Future<void> _updateSubscriptions({
    List<String>? newRegions,
    List<String>? newInterests,
  }) async {
    final regions = newRegions ?? _selectedRegions;
    final interests = newInterests ?? _selectedInterests;

    // Optimistic update
    setState(() {
      _selectedRegions = regions;
      _selectedInterests = interests;
    });

    // Call API
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateNotificationSubscriptions(regions, interests);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // If user data is not loaded yet (shouldn't happen if navigating from settings), handle gracefully
    if (authProvider.userModel == null) {
       return Scaffold(
        appBar: AppBar(title: const Text('通知設定')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (authProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          _buildTopicSubscriptionSection(context, theme),
          const Divider(),
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: Text('當配對成功時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
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
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: Text('當預約有變更時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: Text('接收優惠和活動資訊', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: Text('接收每週電子報', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTopicSubscriptionSection(BuildContext context, ThemeData theme) {
    // Regions
    final allRegions = {
      'taipei': '台北',
      'taichung': '台中',
      'kaohsiung': '高雄',
    };

    // Interests
    final allInterests = {
      'food': '美食',
      'movie': '電影',
      'music': '音樂',
      'tech': '科技',
      'outdoors': '戶外',
      'art': '藝術',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, '主題訂閱'),

        // Regions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('地區', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary
          )),
        ),
        ...allRegions.entries.map((entry) {
          final isSubscribed = _selectedRegions.contains(entry.key);
          return CheckboxListTile(
            title: Text(entry.value),
            value: isSubscribed,
            activeColor: theme.colorScheme.primary,
            onChanged: (bool? value) {
              if (value == null) return;
              final newRegions = List<String>.from(_selectedRegions);
              if (value) {
                newRegions.add(entry.key);
              } else {
                newRegions.remove(entry.key);
              }
              _updateSubscriptions(newRegions: newRegions);
            },
          );
        }),

        const SizedBox(height: 8),

        // Interests
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text('興趣', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary
          )),
        ),
        ...allInterests.entries.map((entry) {
          final isSubscribed = _selectedInterests.contains(entry.key);
          return CheckboxListTile(
            title: Text(entry.value),
            value: isSubscribed,
            activeColor: theme.colorScheme.primary,
            onChanged: (bool? value) {
              if (value == null) return;
              final newInterests = List<String>.from(_selectedInterests);
              if (value) {
                newInterests.add(entry.key);
              } else {
                newInterests.remove(entry.key);
              }
              _updateSubscriptions(newInterests: newInterests);
            },
          );
        }),
      ],
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
