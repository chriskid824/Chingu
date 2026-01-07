import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('關於', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
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
                gradient: AppColorsMinimal.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsMinimal.primary.withOpacity(0.3),
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
            const Text(
              '版本 1.0.0',
              style: TextStyle(fontSize: 16, color: Colors.grey),
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
            const Text(
              'Chingu 是一個創新的社交平台，專為想要認識新朋友、分享美食體驗的人們設計。我們相信，一頓美好的晚餐不僅是味蕾的享受，更是心靈的交流。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            _buildInfoCard(Icons.email, '聯絡我們', 'support@chingu.app'),
            _buildInfoCard(Icons.language, '官方網站', 'www.chingu.app'),
            _buildInfoCard(Icons.description, '服務條款', '查看完整條款'),
            _buildInfoCard(Icons.privacy_tip, '隱私政策', '查看隱私政策'),
            const SizedBox(height: 40),
            const Text(
              '© 2025 Chingu. All rights reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.facebook),
                  onPressed: () {},
                  color: AppColorsMinimal.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: () {},
                  color: AppColorsMinimal.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.link),
                  onPressed: () {},
                  color: AppColorsMinimal.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppColorsMinimal.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: () {},
      ),
    );
  }
}





