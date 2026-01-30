import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/topic_subscription_service.dart';
import 'package:chingu/utils/interest_constants.dart';
import 'package:chingu/models/user_model.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  Future<void> _handleRegionChange(BuildContext context, String region, bool isSubscribed) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    final oldRegions = List<String>.from(user.subscribedRegions);
    final newRegions = List<String>.from(oldRegions);

    if (isSubscribed) {
      if (!newRegions.contains(region)) newRegions.add(region);
    } else {
      newRegions.remove(region);
    }

    // 1. Update FCM topics
    await TopicSubscriptionService().updateRegionSubscriptions(oldRegions, newRegions);

    // 2. Update Firestore
    await authProvider.updateUserData({'subscribedRegions': newRegions});
  }

  Future<void> _showInterestSelectionDialog(BuildContext context, UserModel user) async {
    final theme = Theme.of(context);
    final allInterests = InterestConstants.getAllInterests();
    final selectedInterests = List<String>.from(user.subscribedInterests);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('選擇感興趣的主題'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allInterests.map((interestData) {
                      final interest = interestData['name'] as String;
                      final isSelected = selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedInterests.add(interest);
                            } else {
                              selectedInterests.remove(interest);
                            }
                          });
                        },
                        selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                        checkmarkColor: theme.colorScheme.primary,
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);

                    final oldInterests = List<String>.from(user.subscribedInterests);

                    // Update FCM
                    await TopicSubscriptionService().updateInterestSubscriptions(oldInterests, selectedInterests);

                    // Update Firestore
                    // Warning: Don't use context across async gaps if possible, but here it's likely fine or use a navigator key
                    // To be safe, re-fetch provider
                    if (context.mounted) {
                       await context.read<AuthProvider>().updateUserData({'subscribedInterests': selectedInterests});
                    }
                  },
                  child: const Text('儲存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final user = context.watch<AuthProvider>().user;
    // Fallback if user is null (e.g. loading), though likely authenticated
    final subscribedRegions = user?.subscribedRegions ?? [];
    final subscribedInterests = user?.subscribedInterests ?? [];

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
          // 新增：地區訂閱
          _buildSectionTitle(context, '地區訂閱'),
          ...['台北市', '台中市', '高雄市'].map((region) {
            final isSubscribed = subscribedRegions.contains(region);
            return CheckboxListTile(
              title: Text(region),
              value: isSubscribed,
              onChanged: (bool? value) {
                if (value != null) {
                  _handleRegionChange(context, region, value);
                }
              },
              activeColor: theme.colorScheme.primary,
            );
          }),

          const Divider(),

          // 新增：主題訂閱
          _buildSectionTitle(context, '主題訂閱'),
          ListTile(
            title: const Text('感興趣的主題'),
            subtitle: Text(
              subscribedInterests.isEmpty
                  ? '尚未訂閱任何主題'
                  : subscribedInterests.join('、'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: user == null ? null : () => _showInterestSelectionDialog(context, user),
          ),

          const Divider(),

          // 原有的（部分功能未實作，保持原樣或稍微清理）
          _buildSectionTitle(context, '推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: Text('接收應用程式的推播通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true, // Placeholder
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          // ... (Existing dummy settings)
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
