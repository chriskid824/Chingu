import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  Set<String> _subscribedTopics = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        setState(() {
          _subscribedTopics = Set.from(user.subscribedTopics);
        });
      }
    });
  }

  Future<void> _toggleTopic(String topic, bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Optimistic update
    final previousState = Set<String>.from(_subscribedTopics);
    if (value) {
      _subscribedTopics.add(topic);
    } else {
      _subscribedTopics.remove(topic);
    }

    try {
      final notificationService = NotificationService();
      final authProvider = context.read<AuthProvider>();

      if (value) {
        await notificationService.subscribeToTopic(topic);
      } else {
        await notificationService.unsubscribeFromTopic(topic);
      }

      // Update Firestore
      await authProvider.updateUserData({
        'subscribedTopics': _subscribedTopics.toList(),
      });
    } catch (e) {
      // Revert on failure
      if (mounted) {
        setState(() {
          _subscribedTopics = previousState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('設定更新失敗: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  color: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: ListView(
        children: [
          // 地區訂閱
          _buildSectionTitle(context, '地區訂閱 (Region Subscription)'),
          _buildTopicCheckbox('台北 (Taipei)', 'region_taipei', theme),
          _buildTopicCheckbox('台中 (Taichung)', 'region_taichung', theme),
          _buildTopicCheckbox('高雄 (Kaohsiung)', 'region_kaohsiung', theme),

          const Divider(),

          // 興趣訂閱
          _buildSectionTitle(context, '興趣訂閱 (Interest Subscription)'),
          _buildTopicCheckbox('休閒娛樂 (Entertainment)', 'interest_entertainment', theme),
          _buildTopicCheckbox('生活風格 (Lifestyle)', 'interest_lifestyle', theme),
          _buildTopicCheckbox('運動健身 (Sports)', 'interest_sports', theme),
          _buildTopicCheckbox('藝術創意 (Arts)', 'interest_arts', theme),
          _buildTopicCheckbox('科技與知識 (Tech)', 'interest_tech', theme),

          const Divider(),

          // 其他通知 (保留原有 UI)
          _buildSectionTitle(context, '一般通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: Text('當有人喜歡您時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true, // Placeholder
            onChanged: (v) {}, // Placeholder
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: Text('收到新訊息時通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true, // Placeholder
            onChanged: (v) {}, // Placeholder
            activeColor: theme.colorScheme.primary,
          ),
          ListTile(
            title: const Text('顯示訊息預覽'),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notificationPreview);
            },
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

  Widget _buildTopicCheckbox(String title, String topic, ThemeData theme) {
    final isSubscribed = _subscribedTopics.contains(topic);
    return CheckboxListTile(
      title: Text(title),
      value: isSubscribed,
      onChanged: (bool? value) {
        if (value != null) {
          _toggleTopic(topic, value);
        }
      },
      activeColor: theme.colorScheme.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
