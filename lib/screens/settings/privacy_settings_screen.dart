import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/auth_provider.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            subtitle: Text('讓其他用戶看到您的年齡', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示職業'),
            subtitle: Text('讓其他用戶看到您的職業', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('顯示位置'),
            subtitle: Text('讓其他用戶看到您的大致位置', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: true,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '配對設定'),
          SwitchListTile(
            title: const Text('只接受已驗證用戶的配對'),
            subtitle: Text('提高配對品質', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          SwitchListTile(
            title: const Text('自動接受配對'),
            subtitle: Text('自動接受符合條件的配對請求', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            value: false,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
          ),
          const Divider(),
          _buildSectionTitle(context, '帳號安全'),
          ListTile(
            leading: Icon(Icons.lock_outline, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            title: const Text('變更密碼'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.phone_android, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            title: const Text('雙重驗證'),
            subtitle: Text('已啟用', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionTitle(context, '資料管理'),
          ListTile(
            leading: Icon(Icons.download, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            title: const Text('下載我的資料'),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
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
                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('刪除帳號'),
                      content: const Text('您確定要刪除帳號嗎？所有資料將被永久刪除且無法復原。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            
                            // 顯示載入指示器
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (loadingContext) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            
                            // 執行刪除帳號
                            final authProvider = context.read<AuthProvider>();
                            final success = await authProvider.deleteAccount();
                            
                            // 關閉載入指示器
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                            
                            if (success && context.mounted) {
                              // 刪除成功，導航到登入頁
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                AppRoutes.login,
                                (route) => false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('帳號已成功刪除')),
                              );
                            } else if (context.mounted) {
                              // 刪除失敗
                              final errorMsg = authProvider.errorMessage ?? '刪除帳號失敗';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          },
                          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                          child: const Text('刪除'),
                        ),
                      ],
                    ),
                  );
                },
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}





