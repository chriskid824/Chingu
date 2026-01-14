import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({super.key});

  @override
  State<PrivacyModeScreen> createState() => _PrivacyModeScreenState();
}

class _PrivacyModeScreenState extends State<PrivacyModeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildSectionTitle(context, '在線狀態'),
              SwitchListTile(
                title: const Text('隱藏在線狀態'),
                subtitle: Text(
                  '開啟後，其他用戶將無法看到您目前是否在線',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.hideOnlineStatus,
                onChanged: (bool value) {
                  authProvider.updateUserData({'hideOnlineStatus': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('隱藏最後上線時間'),
                subtitle: Text(
                  '開啟後，其他用戶將無法看到您上次上線的時間',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.hideLastSeen,
                onChanged: (bool value) {
                  authProvider.updateUserData({'hideLastSeen': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '注意：開啟隱私模式可能會影響您的配對成功率，因為活躍用戶通常更受歡迎。',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
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
