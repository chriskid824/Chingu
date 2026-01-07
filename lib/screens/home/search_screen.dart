import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: AppColorsMinimal.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColorsMinimal.surfaceVariant),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜尋用戶、興趣...',
              hintStyle: TextStyle(color: AppColorsMinimal.textTertiary),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColorsMinimal.primary,
              ),
              suffixIcon: Icon(
                Icons.tune_rounded,
                color: AppColorsMinimal.secondary,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 熱門搜尋
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.whatshot_rounded,
                  color: AppColorsMinimal.warning,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '熱門搜尋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTagChip('義式料理', Icons.local_pizza_rounded, AppColorsMinimal.primary),
                _buildTagChip('日本料理', Icons.ramen_dining_rounded, AppColorsMinimal.error),
                _buildTagChip('咖啡廳', Icons.local_cafe_rounded, AppColorsMinimal.warning),
                _buildTagChip('火鍋', Icons.soup_kitchen_rounded, AppColorsMinimal.secondary),
                _buildTagChip('燒烤', Icons.outdoor_grill_rounded, AppColorsMinimal.success),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          const Divider(height: 1),
          
          const SizedBox(height: 16),
          
          // 最近搜尋
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.history_rounded,
                  color: AppColorsMinimal.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '最近搜尋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    '清除',
                    style: TextStyle(
                      color: AppColorsMinimal.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          Expanded(
            child: ListView(
              children: [
                _buildSearchHistoryItem(
                  Icons.person_rounded,
                  '王小華',
                  AppColorsMinimal.primary,
                ),
                _buildSearchHistoryItem(
                  Icons.location_on_rounded,
                  '信義區 義式餐廳',
                  AppColorsMinimal.secondary,
                ),
                _buildSearchHistoryItem(
                  Icons.person_rounded,
                  '李小美',
                  AppColorsMinimal.success,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTagChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchHistoryItem(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 20,
            color: AppColorsMinimal.textTertiary,
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
