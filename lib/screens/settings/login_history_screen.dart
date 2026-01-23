import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:chingu/providers/auth_provider.dart';

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.uid;
    final theme = Theme.of(context);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('登入紀錄')),
        body: const Center(child: Text('請先登入')),
      );
    }

    final loginHistoryService = LoginHistoryService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('登入紀錄'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: StreamBuilder<List<LoginHistoryModel>>(
        stream: loginHistoryService.getLoginHistory(userId),
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
                    Icons.history,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '尚無登入紀錄',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: historyList.length,
            separatorBuilder: (context, index) => const Divider(indent: 72),
            itemBuilder: (context, index) {
              final record = historyList[index];
              final dateFormat = DateFormat('yyyy/MM/dd HH:mm');

              IconData deviceIcon = Icons.devices;
              if (record.device.toLowerCase().contains('android')) {
                deviceIcon = Icons.android;
              } else if (record.device.toLowerCase().contains('ios') ||
                         record.device.toLowerCase().contains('iphone')) {
                deviceIcon = Icons.phone_iphone;
              } else if (record.device.toLowerCase().contains('web')) {
                deviceIcon = Icons.web;
              }

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(deviceIcon, color: theme.colorScheme.primary),
                ),
                title: Text(
                  dateFormat.format(record.loginTime),
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${record.location} • ${record.device}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
