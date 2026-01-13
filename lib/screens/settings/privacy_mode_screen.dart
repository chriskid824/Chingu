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
              '隱私模式讓您可以控制其他用戶何時可以看到您的在線狀態和活動時間。',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('顯示在線狀態'),
            subtitle: Text(
              '允許其他用戶看到您目前在線',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))
            ),
            value: user.isOnlineStatusVisible,
            onChanged: (bool value) {
              authProvider.updateUserData({'isOnlineStatusVisible': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示最後上線時間'),
            subtitle: Text(
              '允許其他用戶看到您上次上線的時間',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))
            ),
            value: user.isLastSeenVisible,
            onChanged: (bool value) {
              authProvider.updateUserData({'isLastSeenVisible': value});
            },
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
