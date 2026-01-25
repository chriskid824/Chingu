import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatelessWidget {
  const PrivacyModeScreen({super.key});

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
                subtitle: Text('其他人將無法看到您目前是否在線', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.isOnlineStatusHidden,
                onChanged: (value) {
                  authProvider.updateUserData({'isOnlineStatusHidden': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Divider(),
              _buildSectionTitle(context, '最後上線'),
              SwitchListTile(
                title: const Text('隱藏最後上線時間'),
                subtitle: Text('其他人將無法看到您最後的上線時間', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                value: user.isLastSeenHidden,
                onChanged: (value) {
                  authProvider.updateUserData({'isLastSeenHidden': value});
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
