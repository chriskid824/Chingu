import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/messaging_service.dart';
import 'package:chingu/utils/interest_constants.dart';

class NotificationTopicSubscriptionScreen extends StatefulWidget {
  const NotificationTopicSubscriptionScreen({super.key});

  @override
  State<NotificationTopicSubscriptionScreen> createState() => _NotificationTopicSubscriptionScreenState();
}

class _NotificationTopicSubscriptionScreenState extends State<NotificationTopicSubscriptionScreen> {
  final List<String> _subscribedTopics = [];
  bool _isLoading = false;

  final List<String> _regions = ['Taipei', 'Taichung', 'Kaohsiung'];

  @override
  void initState() {
    super.initState();
    final userModel = context.read<AuthProvider>().userModel;
    if (userModel != null) {
      _subscribedTopics.addAll(userModel.notificationTopics);
    }
  }

  Future<void> _toggleSubscription(String topic) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_subscribedTopics.contains(topic)) {
        await MessagingService().unsubscribeFromTopic(topic);
        _subscribedTopics.remove(topic);
      } else {
        await MessagingService().subscribeToTopic(topic);
        _subscribedTopics.add(topic);
      }

      // Update Firestore
      await context.read<AuthProvider>().updateUserData({
        'notificationTopics': _subscribedTopics,
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新訂閱失敗: $e')),
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
      appBar: AppBar(
        title: const Text('訂閱主題', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '地區訂閱',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ..._regions.map((region) {
                final topic = MessagingService.getRegionTopic(region);
                final isSubscribed = _subscribedTopics.contains(topic);

                // 顯示名稱 (英文 region 對應中文)
                String displayName = region;
                if (region == 'Taipei') displayName = '台北';
                if (region == 'Taichung') displayName = '台中';
                if (region == 'Kaohsiung') displayName = '高雄';

                return CheckboxListTile(
                  title: Text(displayName),
                  value: isSubscribed,
                  onChanged: (value) => _toggleSubscription(topic),
                  activeColor: theme.colorScheme.primary,
                );
              }),

              const SizedBox(height: 24),
              Text(
                '興趣訂閱',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...InterestConstants.categories.expand((category) {
                return (category['interests'] as List<Map<String, dynamic>>).map((interest) {
                  final interestId = interest['id'] as String;
                  final topic = MessagingService.getInterestTopic(interestId);
                  final isSubscribed = _subscribedTopics.contains(topic);

                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Icon(interest['icon'] as IconData, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(interest['name'] as String),
                      ],
                    ),
                    value: isSubscribed,
                    onChanged: (value) => _toggleSubscription(topic),
                    activeColor: theme.colorScheme.primary,
                  );
                });
              }),
            ],
          ),
    );
  }
}
