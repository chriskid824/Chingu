import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatelessWidget {
  const PrivacyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.scaffoldBackgroundColor,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '管理您的在線狀態和上線時間的可見性。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('隱藏在線狀態'),
            subtitle: Text('不向其他用戶顯示您目前在線', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: user.hideOnlineStatus,
            onChanged: (bool value) {
              context.read<AuthProvider>().updateUserData({'hideOnlineStatus': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('隱藏最後上線時間'),
            subtitle: Text('不向其他用戶顯示您最後上線的時間', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: user.hideLastSeen,
            onChanged: (bool value) {
              context.read<AuthProvider>().updateUserData({'hideLastSeen': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
