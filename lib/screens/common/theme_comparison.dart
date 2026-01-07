import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/core/theme/app_colors.dart';

/// 主題對比預覽頁面
/// 左側：原本的橙色風格
/// 右側：新的極簡紫色風格
class ThemeComparison extends StatelessWidget {
  const ThemeComparison({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主題風格對比'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 平板或橫屏：左右分屏
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                Expanded(
                  child: _ThemePreview(
                    title: '原本風格（溫暖橙）',
                    theme: AppTheme.themeFor(AppThemePreset.orange),
                    colorName: '#FF6B35',
                  ),
                ),
                Container(width: 2, color: Colors.grey.shade300),
                Expanded(
                  child: _ThemePreview(
                    title: '極簡風格（靛藍紫）',
                    theme: AppTheme.themeFor(AppThemePreset.minimal),
                    colorName: '#6366F1',
                  ),
                ),
              ],
            );
          }
          
          // 手機：上下滾動
          return ListView(
            children: [
              _ThemePreview(
                title: '原本風格（溫暖橙）',
                theme: AppTheme.themeFor(AppThemePreset.orange),
                colorName: '#FF6B35',
              ),
              const Divider(height: 32, thickness: 2),
              _ThemePreview(
                title: '極簡風格（靛藍紫）',
                theme: AppTheme.themeFor(AppThemePreset.minimal),
                colorName: '#6366F1',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final String title;
  final ThemeData theme;
  final String colorName;

  const _ThemePreview({
    required this.title,
    required this.theme,
    required this.colorName,
  });

  @override
  Widget build(BuildContext context) {
    final chinguTheme = theme.extension<ChinguTheme>();
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          return Container(
            color: theme.scaffoldBackgroundColor,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 標題
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 配色展示
                _buildColorPalette(context),
                const SizedBox(height: 24),

                // 漸層效果展示（僅極簡風格）
                if (chinguTheme != null)
                  _buildGradientShowcase(context, chinguTheme),
                if (chinguTheme != null)
                  const SizedBox(height: 24),

                // 按鈕展示
                _buildButtonsSection(context),
                const SizedBox(height: 24),

                // 卡片展示
                _buildCardsSection(context),
                const SizedBox(height: 24),

                // 輸入框展示
                _buildInputsSection(context),
                const SizedBox(height: 24),

                // Chips 展示
                _buildChipsSection(context),
                const SizedBox(height: 24),

                // 文字樣式展示
                _buildTextStylesSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildColorPalette(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配色方案',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildColorBox('主色', theme.colorScheme.primary),
                const SizedBox(width: 8),
                _buildColorBox('次要色', theme.colorScheme.secondary),
                const SizedBox(width: 8),
                _buildColorBox('背景', theme.scaffoldBackgroundColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildColorBox('成功', theme.colorScheme.error),
                const SizedBox(width: 8),
                _buildColorBox('警告', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildColorBox('錯誤', theme.colorScheme.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBox(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '按鈕樣式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('主要按鈕'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {},
              child: const Text('次要按鈕'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {},
              child: const Text('文字按鈕'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '卡片樣式',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '使用者名稱',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '這是一個卡片範例',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '卡片內容區域。這裡展示了卡片的圓角、陰影和內邊距效果。',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '輸入框樣式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '標籤文字',
                hintText: '請輸入內容',
                prefixIcon: Icon(Icons.person, color: theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                suffixIcon: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '標籤樣式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: const Text('旅遊'),
                  avatar: const Icon(Icons.travel_explore, size: 18),
                ),
                Chip(
                  label: const Text('美食'),
                  avatar: const Icon(Icons.restaurant, size: 18),
                ),
                Chip(
                  label: const Text('音樂'),
                  avatar: const Icon(Icons.music_note, size: 18),
                ),
                Chip(
                  label: const Text('運動'),
                  avatar: const Icon(Icons.sports_soccer, size: 18),
                ),
                Chip(
                  label: const Text('電影'),
                  avatar: const Icon(Icons.movie, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextStylesSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '文字樣式',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              '大標題 (Display Large)',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '標題 (Headline)',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '副標題 (Title)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '內文 (Body Large) - 這是主要內容文字，用於段落和說明。',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '次要內文 (Body Medium) - 這是次要內容文字。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '輔助文字 (Body Small) - 這是輔助說明文字。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientShowcase(BuildContext context, ChinguTheme chinguTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '✨ 漸層與透明效果',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        
        // 主色漸層
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: chinguTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '主色漸層',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 透明漸層卡片
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: chinguTheme.transparentGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              '透明漸層（清新感）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 玻璃質感
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: chinguTheme.glassGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Center(
            child: Text(
              '玻璃質感（毛玻璃效果）',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // 次要漸層
        Container(
          height: 120,
          decoration: BoxDecoration(
            gradient: chinguTheme.secondaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              '次要漸層（薰衣草到粉紫）',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
