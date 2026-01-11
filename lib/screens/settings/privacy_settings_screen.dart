import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('隱私設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle(context, '個人資料可見性'),
          SwitchListTile(
            title: const Text('顯示年齡'),
            subtitle: Text('讓其他用戶看到您的年齡', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示職業'),
            subtitle: Text('讓其他用戶看到您的職業', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示位置'),
            subtitle: Text('讓其他用戶看到您的大致位置', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對設定'),
          SwitchListTile(
            title: const Text('只接受已驗證用戶的配對'),
            subtitle: Text('提高配對品質', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('自動接受配對'),
            subtitle: Text('自動接受符合條件的配對請求', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '帳號安全'),
          ListTile(
            leading: Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('變更密碼'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.phone_android, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('雙重驗證'),
            subtitle: Text('已啟用', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionTitle(context, '資料管理'),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('下載我的資料'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                title: Text(
                  '刪除帳號',
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '此動作無法復原',
                  style: TextStyle(
                    color: theme.colorScheme.error.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
                onTap: () => _showDeleteConfirmationDialog(context),
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);

            return AlertDialog(
              title: const Text('刪除帳號'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('您確定要刪除帳號嗎？此操作將永久刪除：'),
                    const SizedBox(height: 8),
                    _buildWarningItem('• 個人資料與照片'),
                    _buildWarningItem('• 所有配對與聊天記錄'),
                    _buildWarningItem('• 參加的活動記錄'),
                    const SizedBox(height: 16),
                    Text(
                      '此動作無法復原！',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: '請輸入密碼以確認',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          errorStyle: const TextStyle(height: 0.8),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '請輸入密碼';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              actions: [
                if (!isLoading)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                if (!isLoading)
                  TextButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          final success = await context
                              .read<AuthProvider>()
                              .deleteAccount(passwordController.text);

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                            }
                          } else {
                            if (context.mounted) {
                              setState(() {
                                isLoading = false;
                              });
                              // Show error from provider if available
                              final error = context.read<AuthProvider>().errorMessage;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error ?? '刪除失敗，請檢查密碼')),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('發生錯誤: $e')),
                            );
                          }
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    child: const Text('確認刪除'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}





