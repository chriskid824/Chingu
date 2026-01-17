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
  bool _isOnlineStatusVisible = true;
  bool _isLastSeenVisible = true;

  @override
  void initState() {
    super.initState();
    // Initialize with current user settings
    final user = context.read<AuthProvider>().userModel;
    if (user != null) {
      _isOnlineStatusVisible = user.isOnlineStatusVisible;
      _isLastSeenVisible = user.isLastSeenVisible;
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    // Optimistic update
    setState(() {
      if (key == 'isOnlineStatusVisible') {
        _isOnlineStatusVisible = value;
      } else if (key == 'isLastSeenVisible') {
        _isLastSeenVisible = value;
      }
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateUserData({
      key: value,
    });

    if (!success && mounted) {
      // Revert if failed
      setState(() {
        if (key == 'isOnlineStatusVisible') {
          _isOnlineStatusVisible = !value;
        } else if (key == 'isLastSeenVisible') {
          _isLastSeenVisible = !value;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('更新設定失敗，請稍後再試')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ignore: unused_local_variable
    final chinguTheme = theme.extension<ChinguTheme>();

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
              '管理您的在線狀態和最後上線時間的可見性。當您隱藏這些資訊時，您可能也無法看到其他人的狀態。',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('顯示在線狀態'),
            subtitle: Text(
              '允許其他用戶看到您目前在線',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: _isOnlineStatusVisible,
            onChanged: (value) => _updatePrivacySetting('isOnlineStatusVisible', value),
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示最後上線時間'),
            subtitle: Text(
              '允許其他用戶看到您上次使用的時間',
              style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
            value: _isLastSeenVisible,
            onChanged: (value) => _updatePrivacySetting('isLastSeenVisible', value),
            activeColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
