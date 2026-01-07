import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class FilterScreenDemo extends StatelessWidget {
  const FilterScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.tune_rounded,
              color: AppColorsMinimal.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              '篩選條件',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              '重置',
              style: TextStyle(
                color: AppColorsMinimal.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 距離
          _buildSectionTitle(Icons.location_on_rounded, '距離', AppColorsMinimal.primary),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColorsMinimal.primary,
              inactiveTrackColor: AppColorsMinimal.surfaceVariant,
              thumbColor: AppColorsMinimal.primary,
              overlayColor: AppColorsMinimal.primary.withOpacity(0.2),
            ),
            child: Slider(
              value: 5,
              min: 1,
              max: 50,
              divisions: 49,
              label: '5 公里',
              onChanged: (v) {},
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColorsMinimal.primary.withOpacity(0.15),
                    AppColorsMinimal.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '5 公里',
                style: TextStyle(
                  color: AppColorsMinimal.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 年齡範圍
          _buildSectionTitle(Icons.cake_rounded, '年齡範圍', AppColorsMinimal.secondary),
          const SizedBox(height: 12),
          RangeSlider(
            values: const RangeValues(25, 35),
            min: 18,
            max: 60,
            divisions: 42,
            labels: const RangeLabels('25', '35'),
            onChanged: (v) {},
            activeColor: AppColorsMinimal.secondary,
            inactiveColor: AppColorsMinimal.surfaceVariant,
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColorsMinimal.secondary.withOpacity(0.15),
                    AppColorsMinimal.secondary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '25 - 35 歲',
                style: TextStyle(
                  color: AppColorsMinimal.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // 預算範圍
          _buildSectionTitle(Icons.payments_rounded, '預算範圍', AppColorsMinimal.success),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBudgetChip('NT\$ 300-500', false),
              _buildBudgetChip('NT\$ 500-800', true),
              _buildBudgetChip('NT\$ 800-1200', false),
              _buildBudgetChip('NT\$ 1200+', false),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 興趣
          _buildSectionTitle(Icons.interests_rounded, '興趣', AppColorsMinimal.warning),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInterestChip('美食', Icons.restaurant_rounded, true),
              _buildInterestChip('旅遊', Icons.flight_rounded, true),
              _buildInterestChip('電影', Icons.movie_rounded, false),
              _buildInterestChip('音樂', Icons.music_note_rounded, false),
              _buildInterestChip('運動', Icons.sports_soccer_rounded, false),
              _buildInterestChip('閱讀', Icons.book_rounded, false),
              _buildInterestChip('攝影', Icons.camera_alt_rounded, false),
              _buildInterestChip('藝術', Icons.palette_rounded, false),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // 驗證狀態
          _buildSectionTitle(Icons.verified_rounded, '驗證狀態', AppColorsMinimal.info),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColorsMinimal.surfaceVariant),
            ),
            child: SwitchListTile(
              title: const Text(
                '只顯示已驗證用戶',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
              subtitle: Text(
                '提高配對品質',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColorsMinimal.textTertiary,
                ),
              ),
              value: true,
              onChanged: (v) {},
              activeColor: AppColorsMinimal.success,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 套用按鈕
          Container(
            decoration: BoxDecoration(
              gradient: AppColorsMinimal.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColorsMinimal.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    '套用篩選',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
  
  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
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
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  AppColorsMinimal.success,
                  AppColorsMinimal.success.withOpacity(0.8),
                ],
              )
            : null,
        color: selected ? null : AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? AppColorsMinimal.success
              : AppColorsMinimal.surfaceVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            const Icon(Icons.check, size: 16, color: Colors.white),
          if (selected) const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInterestChip(String label, IconData icon, bool selected) {
    final colors = [
      AppColorsMinimal.primary,
      AppColorsMinimal.secondary,
      AppColorsMinimal.success,
      AppColorsMinimal.warning,
      AppColorsMinimal.error,
    ];
    final color = colors[label.hashCode % colors.length];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.8),
                ],
              )
            : LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? color : color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : color,
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check, size: 14, color: Colors.white),
          ],
        ],
      ),
    );
  }
}
