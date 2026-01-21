import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/theme/app_theme.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '帳號安全',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(context, '雙因素驗證 (2FA)'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('啟用雙因素驗證'),
                      subtitle: const Text('登入時需要輸入驗證碼，增加帳號安全性'),
                      value: user?.isTwoFactorEnabled ?? false,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (bool value) async {
                        setState(() => _isLoading = true);
                        final success = await authProvider.toggleTwoFactor(value);
                        if (!mounted) return;
                        setState(() => _isLoading = false);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(value ? '已開啟雙因素驗證' : '已關閉雙因素驗證'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authProvider.errorMessage ?? '設定失敗'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    if (user?.isTwoFactorEnabled ?? false) ...[
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('驗證方式'),
                        subtitle: Text(user?.twoFactorMethod == 'sms' ? '簡訊 (SMS)' : '電子郵件 (Email)'),
                        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        onTap: () {
                          // 未來可擴充：切換驗證方式
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('目前僅支援預設驗證方式')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, '登入紀錄'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  title: const Text('上次登入'),
                  subtitle: Text(user?.lastLogin.toString() ?? '未知'),
                  leading: Icon(Icons.history, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
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
