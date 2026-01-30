import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatelessWidget {
  const PrivacyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '管理您的在線狀態可見性',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('隱藏在線狀態'),
            subtitle: Text(
              '啟用後，其他用戶將無法看到您目前是否在線',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: user.hideOnlineStatus,
            onChanged: (val) {
              authProvider.updateUserData({'hideOnlineStatus': val});
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('隱藏最後上線時間'),
            subtitle: Text(
              '啟用後，其他用戶將無法看到您上次上線的時間',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: user.hideLastSeen,
            onChanged: (val) {
              authProvider.updateUserData({'hideLastSeen': val});
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
