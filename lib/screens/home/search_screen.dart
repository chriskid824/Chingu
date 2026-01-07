import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜尋用戶、興趣...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: theme.colorScheme.primary,
              ),
              suffixIcon: Icon(
                Icons.tune_rounded,
                color: chinguTheme?.secondary ?? theme.colorScheme.secondary,
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
                  color: chinguTheme?.warning ?? Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '熱門搜尋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
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
                _buildTagChip('義式料理', Icons.local_pizza_rounded, theme.colorScheme.primary),
                _buildTagChip('日本料理', Icons.ramen_dining_rounded, theme.colorScheme.error),
                _buildTagChip('咖啡廳', Icons.local_cafe_rounded, chinguTheme?.warning ?? Colors.orange),
                _buildTagChip('火鍋', Icons.soup_kitchen_rounded, chinguTheme?.secondary ?? theme.colorScheme.secondary),
                _buildTagChip('燒烤', Icons.outdoor_grill_rounded, chinguTheme?.success ?? Colors.green),
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
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近搜尋',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    '清除',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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
                  context,
                  Icons.person_rounded,
                  '王小華',
                  theme.colorScheme.primary,
                ),
                _buildSearchHistoryItem(
                  context,
                  Icons.location_on_rounded,
                  '信義區 義式餐廳',
                  chinguTheme?.secondary ?? theme.colorScheme.secondary,
                ),
                _buildSearchHistoryItem(
                  context,
                  Icons.person_rounded,
                  '李小美',
                  chinguTheme?.success ?? Colors.green,
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
  
  Widget _buildSearchHistoryItem(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
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
          style: TextStyle(
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.close_rounded,
            size: 20,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
          onPressed: () {},
        ),
      ),
    );
  }
}
