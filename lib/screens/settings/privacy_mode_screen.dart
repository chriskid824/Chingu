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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: userModel == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, '在線狀態'),
                SwitchListTile(
                  title: const Text('顯示在線狀態'),
                  subtitle: Text(
                    '當您在線時，其他用戶可以看到綠色狀態燈',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  value: userModel.showOnlineStatus,
                  onChanged: (value) {
                    context.read<AuthProvider>().updatePrivacySettings(showOnlineStatus: value);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                SwitchListTile(
                  title: const Text('顯示最後上線時間'),
                  subtitle: Text(
                    '允許其他用戶看到您最後一次使用的時間',
                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  value: userModel.showLastSeen,
                  onChanged: (value) {
                    context.read<AuthProvider>().updatePrivacySettings(showLastSeen: value);
                  },
                  activeColor: theme.colorScheme.primary,
                ),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    '注意：如果您關閉了這些選項，您可能也無法看到其他用戶的在線狀態或最後上線時間。',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
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
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
