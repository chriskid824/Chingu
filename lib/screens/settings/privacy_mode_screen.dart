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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '管理您的在線狀態顯示設定',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('顯示在線狀態'),
                  subtitle: Text(
                    '允許其他用戶看到您目前是否在線',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: userModel.showOnlineStatus,
                  onChanged: (value) async {
                    await authProvider.updateUserData({
                      'showOnlineStatus': value,
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('顯示最後上線時間'),
                  subtitle: Text(
                    '允許其他用戶看到您上次上線的時間',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: userModel.showLastSeen,
                  onChanged: (value) async {
                    await authProvider.updateUserData({
                      'showLastSeen': value,
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
    );
  }
}
