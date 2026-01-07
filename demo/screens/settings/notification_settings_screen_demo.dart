import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class NotificationSettingsScreenDemo extends StatelessWidget {
  const NotificationSettingsScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('通知設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('推播通知'),
          SwitchListTile(
            title: const Text('啟用推播通知'),
            subtitle: const Text('接收應用程式的推播通知'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('配對通知'),
          SwitchListTile(
            title: const Text('新配對'),
            subtitle: const Text('當有人喜歡您時通知'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('配對成功'),
            subtitle: const Text('當配對成功時通知'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('訊息通知'),
          SwitchListTile(
            title: const Text('新訊息'),
            subtitle: const Text('收到新訊息時通知'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('顯示訊息預覽'),
            subtitle: const Text('在通知中顯示訊息內容'),
            value: false,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('活動通知'),
          SwitchListTile(
            title: const Text('預約提醒'),
            subtitle: const Text('晚餐前 1 小時提醒'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('預約變更'),
            subtitle: const Text('當預約有變更時通知'),
            value: true,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          const Divider(),
          _buildSectionTitle('行銷通知'),
          SwitchListTile(
            title: const Text('優惠活動'),
            subtitle: const Text('接收優惠和活動資訊'),
            value: false,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
          ),
          SwitchListTile(
            title: const Text('電子報'),
            subtitle: const Text('接收每週電子報'),
            value: false,
            onChanged: (v) {},
            activeColor: AppColorsMinimal.primary,
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





