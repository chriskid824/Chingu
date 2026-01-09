import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class NotificationPreviewScreen extends StatefulWidget {
  const NotificationPreviewScreen({super.key});

  @override
  State<NotificationPreviewScreen> createState() => _NotificationPreviewScreenState();
}

class _NotificationPreviewScreenState extends State<NotificationPreviewScreen> {
  bool _showMessageContent = true;
  bool _showEventDetails = true;
  bool _showMatchDetails = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('預覽設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '選擇在推播通知中顯示的資訊詳細程度。關閉後，通知將只顯示「新訊息」或「新配對」，而不會顯示具體內容。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('顯示訊息內容'),
            subtitle: Text('在通知中顯示發送者和訊息內容', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _showMessageContent,
            onChanged: (v) {
              setState(() => _showMessageContent = v);
            },
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('顯示活動詳情'),
            subtitle: Text('在通知中顯示活動名稱和時間', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _showEventDetails,
            onChanged: (v) {
              setState(() => _showEventDetails = v);
            },
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('顯示配對詳情'),
            subtitle: Text('在通知中顯示配對對象的名稱', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: _showMatchDetails,
            onChanged: (v) {
              setState(() => _showMatchDetails = v);
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
