import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class InterestsSelectionScreenDemo extends StatelessWidget {
  const InterestsSelectionScreenDemo({super.key});
  
  @override
  Widget build(BuildContext context) {
    final interests = {
      '美食': Icons.restaurant_rounded,
      '旅遊': Icons.flight_rounded,
      '電影': Icons.movie_rounded,
      '音樂': Icons.music_note_rounded,
      '運動': Icons.sports_soccer_rounded,
      '閱讀': Icons.book_rounded,
      '攝影': Icons.camera_alt_rounded,
      '藝術': Icons.palette_rounded,
      '科技': Icons.computer_rounded,
      '寵物': Icons.pets_rounded,
      '咖啡': Icons.local_cafe_rounded,
      '烹飪': Icons.soup_kitchen_rounded,
    };
    
    final selectedInterests = ['美食', '旅遊', '攝影'];
    
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text('選擇興趣', style: TextStyle(fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColorsMinimal.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // 進度條
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      gradient: index <= 1 
                          ? AppColorsMinimal.primaryGradient
                          : null,
                      color: index <= 1 ? null : AppColorsMinimal.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColorsMinimal.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      const Text('步驟 2/4', style: TextStyle(color: AppColorsMinimal.textTertiary, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('選擇您的興趣', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColorsMinimal.textPrimary)),
                      const SizedBox(width: 8),
                      Text('🎯', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('至少選擇 3 個興趣，幫助我們找到更適合的配對', style: TextStyle(color: AppColorsMinimal.textSecondary, fontSize: 15)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: interests.entries.map((entry) {
                      final selected = selectedInterests.contains(entry.key);
                      final colors = [AppColorsMinimal.primary, AppColorsMinimal.secondary, AppColorsMinimal.success, AppColorsMinimal.warning, AppColorsMinimal.error];
                      final color = colors[entry.key.hashCode % colors.length];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: selected 
                              ? LinearGradient(colors: [color, color.withOpacity(0.8)])
                              : LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? color : color.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(entry.value, size: 18, color: selected ? Colors.white : color),
                            const SizedBox(width: 8),
                            Text(entry.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: selected ? Colors.white : color)),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check, size: 16, color: Colors.white),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppColorsMinimal.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: AppColorsMinimal.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('下一步', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
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
}
