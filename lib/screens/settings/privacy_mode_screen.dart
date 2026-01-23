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
    final userModel = authProvider.userModel;

    if (userModel == null) {
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '在線狀態隱私',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('隱藏在線狀態'),
            subtitle: Text('啟用後，其他人將無法看到您目前在線', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: userModel.isOnlineStatusHidden,
            onChanged: (bool value) {
              authProvider.updateUserData({'isOnlineStatusHidden': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('隱藏最後上線時間'),
            subtitle: Text('啟用後，其他人將無法看到您上次上線的時間', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: userModel.isLastSeenHidden,
            onChanged: (bool value) {
              authProvider.updateUserData({'isLastSeenHidden': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
