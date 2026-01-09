import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/routes/app_router.dart';

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
          ListTile(
            leading: Icon(Icons.visibility_off_outlined, color: theme.colorScheme.onSurface.withOpacity(0.7)),
            title: const Text('隱私模式'),
            subtitle: Text('管理上線狀態與最後上線時間', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6))),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface.withOpacity(0.3)),
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.privacyMode);
            },
          ),
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
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('刪除帳號', style: TextStyle(color: theme.colorScheme.error)),
            trailing: Icon(Icons.chevron_right, color: theme.colorScheme.error),
            onTap: () {},
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
}





