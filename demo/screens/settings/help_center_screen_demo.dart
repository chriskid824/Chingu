import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class HelpCenterScreenDemo extends StatelessWidget {
  const HelpCenterScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('幫助中心', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: '搜尋問題...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          // FAQ Categories
          const Text(
            '常見問題',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFAQCategory(
            Icons.account_circle,
            '帳號與設定',
            '如何建立帳號、修改個人資料等',
          ),
          _buildFAQCategory(
            Icons.favorite,
            '配對與約會',
            '如何尋找配對、建立預約等',
          ),
          _buildFAQCategory(
            Icons.payment,
            '付款與訂閱',
            '付款方式、訂閱方案等',
          ),
          _buildFAQCategory(
            Icons.security,
            '安全與隱私',
            '帳號安全、隱私保護等',
          ),
          _buildFAQCategory(
            Icons.bug_report,
            '問題回報',
            '回報錯誤、提供建議等',
          ),
          const SizedBox(height: 24),
          const Text(
            '聯絡我們',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    '找不到您需要的答案？',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.email),
                    label: const Text('發送郵件'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsMinimal.primary,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat),
                    label: const Text('線上客服'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFAQCategory(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColorsMinimal.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColorsMinimal.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}





