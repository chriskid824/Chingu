import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class SettingsScreenDemo extends StatelessWidget {
  const SettingsScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: AppColorsMinimal.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColorsMinimal.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded, size: 35, color: Colors.white),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '張小明',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'user@example.com',
                        style: TextStyle(fontSize: 14, color: AppColorsMinimal.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const Divider(),
          // Account Settings
          _buildSectionTitle('帳號設定'),
          _buildListTile(Icons.person_outline, '個人資料', () {}),
          _buildListTile(Icons.favorite_outline, '配對偏好', () {}),
          _buildListTile(Icons.lock_outline, '隱私設定', () {}),
          _buildListTile(Icons.notifications_outlined, '通知設定', () {}),
          const Divider(),
          // App Settings
          _buildSectionTitle('應用程式'),
          _buildListTile(Icons.language, '語言', () {}, trailing: ' 繁體中文'),
          const Divider(),
          // Support
          _buildSectionTitle('支援'),
          _buildListTile(Icons.help_outline, '幫助中心', () {}),
          _buildListTile(Icons.feedback_outlined, '意見回饋', () {}),
          _buildListTile(Icons.star_outline, '評價應用程式', () {}),
          _buildListTile(Icons.info_outline, '關於', () {}, trailing: 'v1.0.0'),
          const Divider(),
          // Logout
          _buildListTile(
            Icons.logout,
            '登出',
            () {},
            textColor: Colors.red,
            iconColor: Colors.red,
          ),
          const SizedBox(height: 24),
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
  
  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    dynamic trailing,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      trailing: trailing is String
          ? Text(trailing, style: const TextStyle(color: Colors.grey))
          : trailing is Widget
              ? trailing
              : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

