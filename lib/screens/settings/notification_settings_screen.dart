import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});
  
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
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.userModel;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: [
              _buildSectionTitle(context, '配對通知'),
              SwitchListTile(
                title: const Text('配對通知'),
                subtitle: Text('接收新配對和配對成功的通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notifyMatch,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notifyMatch': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '訊息通知'),
              SwitchListTile(
                title: const Text('訊息通知'),
                subtitle: Text('接收新訊息的通知', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notifyMessage,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notifyMessage': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '活動通知'),
              SwitchListTile(
                title: const Text('活動通知'),
                subtitle: Text('接收晚餐預約和活動提醒', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.notifyEvent,
                onChanged: (bool value) {
                  authProvider.updateUserData({'notifyEvent': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
            ],
          );
        },
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
}
