import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.userModel;

        // Handle loading or null user
        if (user == null) {
             return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                title: const Text('隱私模式'),
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
            padding: const EdgeInsets.all(16.0),
            children: [
               _buildSwitchTile(
                 context,
                 title: '隱藏在線狀態',
                 subtitle: '隱藏後，其他用戶將無法看到您目前是否在線。',
                 value: user.isOnlineStatusHidden,
                 onChanged: (val) {
                   context.read<AuthProvider>().updateUserData({'isOnlineStatusHidden': val});
                 },
               ),
               const SizedBox(height: 16),
               _buildSwitchTile(
                 context,
                 title: '隱藏最後上線時間',
                 subtitle: '隱藏後，其他用戶將無法看到您的最後上線時間。',
                 value: user.isLastSeenHidden,
                 onChanged: (val) {
                   context.read<AuthProvider>().updateUserData({'isLastSeenHidden': val});
                 },
               ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
