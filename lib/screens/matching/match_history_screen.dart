import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/matching_provider.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // 載入歷史記錄
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.uid != null) {
        context.read<MatchingProvider>().loadMatchHistory(authProvider.uid!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final matchingProvider = context.watch<MatchingProvider>();
    final history = matchingProvider.history;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '配對歷史',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: matchingProvider.isHistoryLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : history.isEmpty
              ? _buildEmptyState(context, theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    final user = item['user'] as UserModel;
                    final swipeData = item['swipe'] as Map<String, dynamic>;

                    return _buildHistoryItem(context, theme, chinguTheme, user, swipeData);
                  },
                ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    ThemeData theme,
    ChinguTheme? chinguTheme,
    UserModel user,
    Map<String, dynamic> swipeData,
  ) {
    final swipeType = swipeData['type'] as String?;
    final isLike = swipeData['isLike'] as bool? ?? false;

    // Determine icon and color based on swipe type
    IconData actionIcon;
    Color actionColor;
    String actionText;

    if (swipeType == 'super_like') {
      actionIcon = Icons.star_rounded;
      actionColor = chinguTheme?.warning ?? Colors.amber;
      actionText = '超級喜歡';
    } else if (swipeType == 'like' || isLike) {
      actionIcon = Icons.favorite_rounded;
      actionColor = chinguTheme?.success ?? Colors.green;
      actionText = '喜歡';
    } else {
      actionIcon = Icons.close_rounded;
      actionColor = chinguTheme?.error ?? Colors.red;
      actionText = '不喜歡';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[200],
                image: user.avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(user.avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: user.avatarUrl == null
                  ? Icon(Icons.person, color: Colors.grey[400])
                  : null,
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.name}, ${user.age}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.city} ${user.district}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Action Status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: actionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(actionIcon, size: 16, color: actionColor),
                      const SizedBox(width: 4),
                      Text(
                        actionText,
                        style: TextStyle(
                          color: actionColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '暫無歷史記錄',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去滑動卡片尋找配對吧！',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}
