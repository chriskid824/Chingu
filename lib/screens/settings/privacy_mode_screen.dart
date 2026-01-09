import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/loading_dialog.dart';

class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({super.key});

  @override
  State<PrivacyModeScreen> createState() => _PrivacyModeScreenState();
}

class _PrivacyModeScreenState extends State<PrivacyModeScreen> {
  bool _isUpdating = false;

  Future<void> _updateSetting(BuildContext context, {bool? showOnlineStatus, bool? showLastSeen}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await authProvider.updateUserData({
        if (showOnlineStatus != null) 'showOnlineStatus': showOnlineStatus,
        if (showLastSeen != null) 'showLastSeen': showLastSeen,
      });

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新設定失敗: ${authProvider.errorMessage ?? "未知錯誤"}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

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

          return Stack(
            children: [
              ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '隱私模式讓您可以控制其他用戶如何看到您的在線狀態。啟用這些設定可以提高隱私保護，但也可能影響您與其他用戶的即時互動體驗。',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const Divider(),
                  _buildSwitchTile(
                    context,
                    title: '顯示上線狀態',
                    subtitle: '讓其他用戶看到您目前在線上',
                    value: user.showOnlineStatus,
                    onChanged: (value) => _updateSetting(context, showOnlineStatus: value),
                  ),
                  _buildSwitchTile(
                    context,
                    title: '顯示最後上線時間',
                    subtitle: '讓其他用戶看到您上次使用的時間',
                    value: user.showLastSeen,
                    onChanged: (value) => _updateSetting(context, showLastSeen: value),
                  ),
                ],
              ),
              if (_isUpdating)
                const Center(child: CircularProgressIndicator()),
            ],
          );
        },
      ),
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

    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
      value: value,
      onChanged: _isUpdating ? null : onChanged,
      activeColor: theme.colorScheme.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
