import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class MessageReactions extends StatelessWidget {
  final Map<String, dynamic> reactions;
  final String currentUserId;
  final Function(String emoji) onReactionSelected;
  final bool isMe;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.currentUserId,
    required this.onReactionSelected,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // 將 reactions 轉換為 List 以便顯示
    final reactionEntries = reactions.entries.toList();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: isMe ? WrapAlignment.end : WrapAlignment.start,
      children: [
        ...reactionEntries.map((entry) {
          final emoji = entry.key;
          final userIds = List<String>.from(entry.value);
          final count = userIds.length;
          final isReactedByMe = userIds.contains(currentUserId);

          if (count == 0) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () => onReactionSelected(emoji),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isReactedByMe
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.cardColor,
                border: Border.all(
                  color: isReactedByMe
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.dividerColor.withOpacity(0.5),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: isReactedByMe
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
                      fontWeight: isReactedByMe ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Add reaction button
        GestureDetector(
          onTap: () => _showEmojiPicker(context),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.cardColor.withOpacity(0.8),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.dividerColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.add_reaction_outlined,
              size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  void _showEmojiPicker(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: ['❤️', '😂', '😮', '😢', '😡', '👍', '👎', '🎉', '🔥', '👀']
                    .map((emoji) => GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            onReactionSelected(emoji);
                          },
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
