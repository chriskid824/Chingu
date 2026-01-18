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
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    // Default to true if user is null or fields are not set
    final showOnlineStatus = user?.showOnlineStatus ?? true;
    final showLastSeen = user?.showLastSeen ?? true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私模式', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isUpdating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _buildSectionTitle(context, '在線狀態隱私'),
                _buildSwitchListTile(
                  context,
                  title: '顯示在線狀態',
                  subtitle: '關閉後，其他人將無法看到您目前是否在線',
                  value: showOnlineStatus,
                  onChanged: (value) => _updatePrivacySetting(
                    context,
                    authProvider,
                    'showOnlineStatus',
                    value,
                  ),
                ),
                const Divider(),
                _buildSectionTitle(context, '最後上線時間'),
                _buildSwitchListTile(
                  context,
                  title: '顯示最後上線時間',
                  subtitle: '關閉後，其他人將無法看到您上次上線的時間',
                  value: showLastSeen,
                  onChanged: (value) => _updatePrivacySetting(
                    context,
                    authProvider,
                    'showLastSeen',
                    value,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '注意：如果您關閉這些設定，您可能也無法看到其他用戶的在線狀態或最後上線時間。',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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

  Widget _buildSwitchListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
    );
  }

  Future<void> _updatePrivacySetting(
    BuildContext context,
    AuthProvider authProvider,
    String field,
    bool value,
  ) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final success = await authProvider.updateUserData({field: value});
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('更新設定失敗，請稍後再試')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e')),
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
}
