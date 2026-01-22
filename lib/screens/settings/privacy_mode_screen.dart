import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
          // 如果正在載入，顯示載入指示器
          if (authProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = authProvider.userModel;
          if (user == null) {
            return const Center(child: Text('無法載入用戶資料'));
          }

          return ListView(
            children: [
              _buildSectionTitle(context, '線上狀態'),
              SwitchListTile(
                title: const Text('隱藏在線狀態'),
                subtitle: Text(
                  '啟用後，其他用戶將無法看到您目前是否在線',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.hideOnlineStatus,
                onChanged: (value) {
                  authProvider.updateUserData({'hideOnlineStatus': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              SwitchListTile(
                title: const Text('隱藏最後上線時間'),
                subtitle: Text(
                  '啟用後，其他用戶將無法看到您最後上線的時間',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.hideLastSeen,
                onChanged: (value) {
                  authProvider.updateUserData({'hideLastSeen': value});
                },
                activeColor: theme.colorScheme.primary,
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '注意：開啟隱私模式可能會降低您在配對中的互動機會，因為其他用戶可能認為您不活躍。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
