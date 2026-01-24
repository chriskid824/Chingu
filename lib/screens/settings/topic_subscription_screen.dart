import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/constants/interest_constants.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/notification_topic_service.dart';

class TopicSubscriptionScreen extends StatefulWidget {
  const TopicSubscriptionScreen({super.key});

  @override
  State<TopicSubscriptionScreen> createState() => _TopicSubscriptionScreenState();
}

class _TopicSubscriptionScreenState extends State<TopicSubscriptionScreen> {
  final NotificationTopicService _topicService = NotificationTopicService();
  bool _isLoading = false;

  Future<void> _toggleSubscription(String topic, bool isSubscribing) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Update Firebase Topic
      if (isSubscribing) {
        await _topicService.subscribeToTopic(topic);
      } else {
        await _topicService.unsubscribeFromTopic(topic);
      }

      // 2. Update Firestore
      final List<String> currentTopics = List.from(user.subscribedTopics);
      if (isSubscribing) {
        if (!currentTopics.contains(topic)) {
          currentTopics.add(topic);
        }
      } else {
        currentTopics.remove(topic);
      }

      await authProvider.updateUserData({
        'subscribedTopics': currentTopics,
      });

    } catch (e) {
      debugPrint('Error toggling subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新訂閱失敗: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final subscribedTopics = user.subscribedTopics;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('主題訂閱', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '訂閱您感興趣的主題，接收相關活動與資訊通知。',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ),

            // 地區訂閱
            _buildSectionTitle(context, '地區資訊'),
            _buildRegionSwitch(context, '台北', 'Taipei', subscribedTopics),
            _buildRegionSwitch(context, '台中', 'Taichung', subscribedTopics),
            _buildRegionSwitch(context, '高雄', 'Kaohsiung', subscribedTopics),

            const Divider(height: 32),

            // 興趣訂閱
            _buildSectionTitle(context, '興趣主題'),
            ...InterestConstants.categories.map((category) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      category['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  ...(category['interests'] as List<Map<String, dynamic>>).map((interest) {
                    final String topic = _topicService.getInterestTopic(interest['id'] as String);
                    final String name = interest['name'] as String;
                    final IconData icon = interest['icon'] as IconData;
                    final bool isSubscribed = subscribedTopics.contains(topic);

                    return SwitchListTile(
                      title: Row(
                        children: [
                          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 12),
                          Text(name),
                        ],
                      ),
                      value: isSubscribed,
                      onChanged: (val) => _toggleSubscription(topic, val),
                      activeColor: theme.colorScheme.primary,
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        ),
    );
  }

  Widget _buildRegionSwitch(BuildContext context, String displayName, String cityKey, List<String> subscribedTopics) {
    final theme = Theme.of(context);
    final topic = _topicService.getRegionTopic(cityKey);
    final isSubscribed = subscribedTopics.contains(topic);

    return SwitchListTile(
      title: Text(displayName),
      subtitle: Text('接收$displayName地區的相關資訊'),
      value: isSubscribed,
      onChanged: (val) => _toggleSubscription(topic, val),
      activeColor: theme.colorScheme.primary,
    );
  }
}
