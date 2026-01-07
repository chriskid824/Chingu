import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class IcebreakerScreen extends StatelessWidget {
  const IcebreakerScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

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
            _buildTopicCard(
              context,
              Icons.restaurant_menu,
              '美食探索',
              '你最喜歡的餐廳是哪一家？',
            ),
            _buildTopicCard(
              context,
              Icons.travel_explore,
              '旅遊經驗',
              '你去過最難忘的地方是哪裡？',
            ),
            _buildTopicCard(
              context,
              Icons.movie,
              '電影音樂',
              '最近有看什麼好看的電影嗎？',
            ),
            _buildTopicCard(
              context,
              Icons.sports_soccer,
              '興趣愛好',
              '你平常喜歡做什麼休閒活動？',
            ),
            _buildTopicCard(
              context,
              Icons.work,
              '工作生活',
              '你的工作中最有趣的部分是什麼？',
            ),
            _buildTopicCard(
              context,
              Icons.pets,
              '寵物',
              '你有養寵物嗎？',
            ),
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
  
  Widget _buildTopicCard(BuildContext context, IconData icon, String title, String question) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    
    final colors = [
      theme.colorScheme.primary, 
      chinguTheme?.secondary ?? Colors.purple, 
      chinguTheme?.success ?? Colors.green, 
      chinguTheme?.warning ?? Colors.orange
    ];
    final color = colors[title.hashCode % colors.length];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
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
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color),
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
              Icon(Icons.send_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}





