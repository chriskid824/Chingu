import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class PrivacySettingsScreenDemo extends StatelessWidget {
  const PrivacySettingsScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('隱私設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('個人資料可見性'),
          SwitchListTile(
            title: const Text('顯示年齡'),
            subtitle: const Text('讓其他用戶看到您的年齡'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('顯示職業'),
            subtitle: const Text('讓其他用戶看到您的職業'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('顯示位置'),
            subtitle: const Text('讓其他用戶看到您的大致位置'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('配對設定'),
          SwitchListTile(
            title: const Text('只接受已驗證用戶的配對'),
            subtitle: const Text('提高配對品質'),
            value: false,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('自動接受配對'),
            subtitle: const Text('自動接受符合條件的配對請求'),
            value: false,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('帳號安全'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('變更密碼'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.phone_android),
            title: const Text('雙重驗證'),
            subtitle: const Text('已啟用'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          _buildSectionTitle('資料管理'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('下載我的資料'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('刪除帳號', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.chevron_right, color: Colors.red),
            onTap: () {},
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }
}





