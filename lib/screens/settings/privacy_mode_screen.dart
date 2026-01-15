import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacyModeScreen extends StatelessWidget {
  const PrivacyModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

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
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(
                context,
                '隱私模式設定',
                '在這裡您可以管理您的在線狀態和最後上線時間的可見性。',
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, '在線狀態'),
              SwitchListTile(
                title: const Text('顯示在線狀態'),
                subtitle: Text(
                  '當您開啟此選項時，其他用戶可以看到您目前是否在線。',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.showOnlineStatus,
                onChanged: (value) async {
                  await authProvider.updateUserData({'showOnlineStatus': value});
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              _buildSectionTitle(context, '最後上線時間'),
              SwitchListTile(
                title: const Text('顯示最後上線時間'),
                subtitle: Text(
                  '當您開啟此選項時，其他用戶可以看到您上次使用 App 的時間。',
                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),
                value: user.showLastSeen,
                onChanged: (value) async {
                  await authProvider.updateUserData({'showLastSeen': value});
                },
                activeColor: theme.colorScheme.primary,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '注意：如果您關閉了這些選項，您可能也無法看到其他用戶的在線狀態和最後上線時間。',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
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
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String description) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
