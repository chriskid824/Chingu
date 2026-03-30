import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';

class IcebreakerScreen extends StatelessWidget {
  const IcebreakerScreen({super.key});

  // 莫蘭迪色系話題色 — 與 GeometricAvatar 同風格
  static const _topicColors = [
    Color(0xFF8B6F5E), // 莫蘭迪棕
    Color(0xFF6B93B8), // 莫蘭迪藍
    Color(0xFF8E7A6D), // 莫蘭迪駝
    Color(0xFF7A9E7E), // 莫蘭迪綠
    Color(0xFF9B7A6A), // 莫蘭迪磚
    Color(0xFF6E8898), // 莫蘭迪灰藍
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> topics = [
      {
        'title': '美食探索',
        'question': '你最喜歡的餐廳是哪一家？',
        'icon': Icons.restaurant_menu_rounded,
        'color': _topicColors[0],
      },
      {
        'title': '旅遊經驗',
        'question': '你去過最難忘的地方是哪裡？',
        'icon': Icons.flight_takeoff_rounded,
        'color': _topicColors[1],
      },
      {
        'title': '電影音樂',
        'question': '最近有看什麼好看的電影嗎？',
        'icon': Icons.movie_filter_rounded,
        'color': _topicColors[2],
      },
      {
        'title': '興趣愛好',
        'question': '你平常喜歡做什麼休閒活動？',
        'icon': Icons.sports_esports_rounded,
        'color': _topicColors[3],
      },
      {
        'title': '工作生活',
        'question': '你的工作中最有趣的部分是什麼？',
        'icon': Icons.work_outline_rounded,
        'color': _topicColors[4],
      },
      {
        'title': '寵物',
        'question': '你有養寵物嗎？',
        'icon': Icons.pets_rounded,
        'color': _topicColors[5],
      },
    ];

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: Text('破冰話題',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          )),
        backgroundColor: AppColorsMinimal.background,
        foregroundColor: AppColorsMinimal.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                boxShadow: [
                  BoxShadow(
                    color: AppColorsMinimal.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 48, color: Colors.white),
                  SizedBox(height: AppColorsMinimal.spaceLG),
                  Text(
                    '需要一些話題靈感？',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppColorsMinimal.spaceSM),
                  Text(
                    '選擇一個話題開始對話',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceXL),
            Text(
              '熱門話題',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: AppColorsMinimal.spaceMD),
            ...topics.map((topic) => _buildTopicCard(
                  context,
                  topic['icon'] as IconData,
                  topic['title'] as String,
                  topic['question'] as String,
                  topic['color'] as Color,
                )),
            const SizedBox(height: AppColorsMinimal.spaceXL),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.refresh_rounded, color: AppColorsMinimal.primary),
              label: Text('換一批話題', style: TextStyle(color: AppColorsMinimal.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppColorsMinimal.spaceLG),
                side: BorderSide(color: AppColorsMinimal.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    IconData icon,
    String title,
    String question,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        child: Padding(
          padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppColorsMinimal.spaceMD),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppColorsMinimal.spaceLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppColorsMinimal.spaceXS),
                    Text(
                      question,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColorsMinimal.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColorsMinimal.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
