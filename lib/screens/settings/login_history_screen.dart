import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;

    if (userId == null) {
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
        stream: LoginHistoryService().getLoginHistory(userId),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無登入記錄',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
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
          Icons.devices_rounded,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(
        history.location.isNotEmpty ? history.location : '未知地點',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            history.deviceInfo,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dateFormat.format(history.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          if (history.ipAddress != null && history.ipAddress!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'IP: ${history.ipAddress}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
