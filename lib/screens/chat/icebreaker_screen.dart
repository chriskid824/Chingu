import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class IcebreakerScreen extends StatelessWidget {
  const IcebreakerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Define topics with specific lively colors
    final List<Map<String, dynamic>> topics = [
      {
        'title': '美食探索',
        'question': '你最喜歡的餐廳是哪一家？',
        'icon': Icons.restaurant_menu_rounded,
        'color': const Color(0xFFFF7043), // Deep Orange
      },
      {
        'title': '旅遊經驗',
        'question': '你去過最難忘的地方是哪裡？',
        'icon': Icons.flight_takeoff_rounded,
        'color': const Color(0xFF42A5F5), // Blue
      },
      {
        'title': '電影音樂',
        'question': '最近有看什麼好看的電影嗎？',
        'icon': Icons.movie_filter_rounded,
        'color': const Color(0xFFAB47BC), // Purple
      },
      {
        'title': '興趣愛好',
        'question': '你平常喜歡做什麼休閒活動？',
        'icon': Icons.sports_esports_rounded,
        'color': const Color(0xFF66BB6A), // Green
      },
      {
        'title': '工作生活',
        'question': '你的工作中最有趣的部分是什麼？',
        'icon': Icons.work_outline_rounded,
        'color': const Color(0xFF5C6BC0), // Indigo
      },
      {
        'title': '寵物',
        'question': '你有養寵物嗎？',
        'icon': Icons.pets_rounded,
        'color': const Color(0xFF8D6E63), // Brown
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('破冰話題', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 48, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '需要一些話題靈感？',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '選擇一個話題開始對話',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '熱門話題',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...topics.map((topic) => _buildTopicCard(
                  context,
                  topic['icon'] as IconData,
                  topic['title'] as String,
                  topic['question'] as String,
                  topic['color'] as Color,
                )),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.refresh_rounded, color: theme.colorScheme.primary),
              label: Text('換一批話題', style: TextStyle(color: theme.colorScheme.primary)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2), // Subtle colored border
        ),
        boxShadow: [
          BoxShadow(
            color: chinguTheme?.shadowLight ?? Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: color.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
