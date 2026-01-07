import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventRatingScreen extends StatelessWidget {
  const EventRatingScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.star_rounded, color: chinguTheme?.warning ?? Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text('評價晚餐', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('6人晚餐聚會', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            Text('2025/10/15 19:00', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: chinguTheme?.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            Text('整體評價', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(index < 4 ? Icons.star : Icons.star_border, size: 40, color: chinguTheme?.warning ?? Colors.amber),
                  onPressed: () {},
                );
              }),
            ),
            const SizedBox(height: 32),
            Text('您的感想', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '分享您的用餐體驗...',
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: chinguTheme?.surfaceVariant ?? theme.dividerColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 24),
            Text('快速標籤', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTagChip('有趣', Icons.mood_rounded, theme.colorScheme.primary),
                _buildTagChip('健談', Icons.chat_rounded, chinguTheme?.secondary ?? Colors.purple),
                _buildTagChip('準時', Icons.schedule_rounded, chinguTheme?.success ?? Colors.green),
                _buildTagChip('有禮貌', Icons.sentiment_satisfied_rounded, chinguTheme?.warning ?? Colors.amber),
                _buildTagChip('話題豐富', Icons.lightbulb_rounded, theme.colorScheme.error),
                _buildTagChip('氣氛愉快', Icons.celebration_rounded, Colors.lightBlue),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('提交評價', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTagChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }
}
