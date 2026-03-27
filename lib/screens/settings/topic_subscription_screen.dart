import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/core/constants/interests_constants.dart';
import 'package:chingu/core/constants/notification_constants.dart';

class TopicSubscriptionScreen extends StatefulWidget {
  const TopicSubscriptionScreen({super.key});

  @override
  State<TopicSubscriptionScreen> createState() => _TopicSubscriptionScreenState();
}

class _TopicSubscriptionScreenState extends State<TopicSubscriptionScreen> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subscribedTopics = user.subscribedTopics;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('主題訂閱', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        bottom: _isUpdating
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2.0),
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                ),
              )
            : null,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '訂閱您感興趣的主題以接收相關推送通知。',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
          ),
          _buildSectionTitle(context, '地區訂閱'),
          ...NotificationConstants.regionTopics.entries.map((entry) {
            final regionName = entry.key;
            final topic = entry.value;
            final isSubscribed = subscribedTopics.contains(topic);

            return SwitchListTile(
              title: Text(regionName),
              subtitle: Text('接收${regionName}地區的活動通知'),
              value: isSubscribed,
              onChanged: _isUpdating ? null : (value) => _handleTopicToggle(topic, value, authProvider),
              activeColor: theme.colorScheme.primary,
            );
          }),
          const Divider(),
          _buildSectionTitle(context, '興趣訂閱'),
          ...InterestsConstants.categories.map((category) {
            return ExpansionTile(
              title: Text(category.name),
              initiallyExpanded: true,
              children: category.interests.map((interest) {
                final topic = NotificationConstants.getTopicForInterest(interest.id);
                final isSubscribed = subscribedTopics.contains(topic);

                return SwitchListTile(
                  secondary: Icon(interest.icon, color: theme.colorScheme.primary),
                  title: Text(interest.name),
                  value: isSubscribed,
                  onChanged: _isUpdating ? null : (value) => _handleTopicToggle(topic, value, authProvider),
                  activeColor: theme.colorScheme.primary,
                );
              }).toList(),
            );
          }),
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

  Future<void> _handleTopicToggle(String topic, bool value, AuthProvider authProvider) async {
    setState(() => _isUpdating = true);

    try {
      final notificationService = NotificationService();

      // 1. Subscribe/Unsubscribe in FCM
      if (value) {
        await notificationService.subscribeToTopic(topic);
      } else {
        await notificationService.unsubscribeFromTopic(topic);
      }

      // 2. Update Firestore User Model
      // We read the current list again to be safe
      final currentTopics = List<String>.from(authProvider.userModel?.subscribedTopics ?? []);

      if (value) {
        if (!currentTopics.contains(topic)) currentTopics.add(topic);
      } else {
        currentTopics.remove(topic);
      }

      await authProvider.updateUserData({'subscribedTopics': currentTopics});

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新失敗: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }
}
