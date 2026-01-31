import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/providers/auth_provider.dart';

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreService = FirestoreService();

    // 確保用戶已登入
    if (authProvider.uid == null) {
       return Scaffold(
        appBar: AppBar(title: const Text('登入歷史')),
        body: const Center(child: Text('請先登入')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '登入歷史',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: StreamBuilder<List<LoginHistoryModel>>(
        stream: firestoreService.getLoginHistory(authProvider.uid!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final historyList = snapshot.data ?? [];

          if (historyList.isEmpty) {
            return Center(
              child: Text(
                '尚無登入記錄',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: historyList.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final history = historyList[index];
              return _buildHistoryItem(context, history);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, LoginHistoryModel history) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.devices,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        dateFormat.format(history.timestamp.toLocal()),
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Text(
                history.location ?? '未知位置',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.phone_android_outlined, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${history.deviceInfo} (${history.os})',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (history.ipAddress != null) ...[
            const SizedBox(height: 2),
             Row(
              children: [
                Icon(Icons.wifi, size: 14, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                const SizedBox(width: 4),
                Text(
                  history.ipAddress!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
