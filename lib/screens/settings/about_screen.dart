import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('關於', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient ??
                    LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary,
                      ],
                    ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chingu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '版本 1.0.0',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '讓每一次晚餐都有意義',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chingu 是一個創新的社交平台，專為想要認識新朋友、分享美食體驗的人們設計。我們相信，一頓美好的晚餐不僅是味蕾的享受，更是心靈的交流。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(
              Icons.email,
              '聯絡我們',
              'support@chingu.app',
              theme.colorScheme.primary,
            ),
            _buildInfoCard(
              Icons.language,
              '官方網站',
              'www.chingu.app',
              theme.colorScheme.primary,
            ),
            _buildInfoCard(
              Icons.description,
              '服務條款',
              '查看完整條款',
              theme.colorScheme.primary,
            ),
            _buildInfoCard(
              Icons.privacy_tip,
              '隱私政策',
              '查看隱私政策',
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 40),
            Text(
              '© 2025 Chingu. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook),
                  onPressed: () {},
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {},
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: () {},
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {},
      ),
    );
  }
}





