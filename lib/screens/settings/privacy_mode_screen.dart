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
    final userModel = authProvider.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '隱私模式',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, '在線狀態'),
                SwitchListTile(
                  title: Text(
                    '隱藏在線狀態',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    '啟用後，其他用戶將無法看到您目前是否在線',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: userModel.isOnlineStatusHidden,
                  onChanged: (bool value) {
                    authProvider.updateUserData({
                      'isOnlineStatusHidden': value,
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
                const Divider(),
                _buildSectionTitle(context, '最後上線時間'),
                SwitchListTile(
                  title: Text(
                    '隱藏最後上線時間',
                    style: theme.textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    '啟用後，其他用戶將無法看到您上次使用應用程式的時間',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  value: userModel.isLastSeenHidden,
                  onChanged: (bool value) {
                    authProvider.updateUserData({
                      'isLastSeenHidden': value,
                    });
                  },
                  activeColor: theme.colorScheme.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
