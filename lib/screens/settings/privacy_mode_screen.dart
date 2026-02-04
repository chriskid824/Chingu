import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatelessWidget {
  const PrivacyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '在線狀態設定'),
          SwitchListTile(
            title: const Text('顯示在線狀態'),
            subtitle: Text(
              '允許其他用戶看到您目前是否在線',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: user.isOnlineStatusVisible,
            onChanged: (value) {
              context.read<AuthProvider>().updateUserData({
                'isOnlineStatusVisible': value,
              });
            },
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示最後上線時間'),
            subtitle: Text(
              '允許其他用戶看到您上次上線的時間',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: user.isLastSeenVisible,
            onChanged: (value) {
              context.read<AuthProvider>().updateUserData({
                'isLastSeenVisible': value,
              });
            },
            activeColor: theme.colorScheme.primary,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '注意：如果您關閉這些選項，您可能也無法看到其他用戶的在線狀態或最後上線時間。',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
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
