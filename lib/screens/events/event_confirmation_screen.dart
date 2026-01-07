import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';

class EventConfirmationScreen extends StatelessWidget {
  const EventConfirmationScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: chinguTheme?.transparentGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                children: [
                const SizedBox(height: 60),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [(chinguTheme?.success ?? Colors.green).withOpacity(0.2), Colors.transparent]),
                      ),
                    ),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: chinguTheme?.successGradient,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: (chinguTheme?.success ?? Colors.green).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                      child: const Icon(Icons.check_circle, size: 80, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('預約成功！', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(width: 8),
                    const Text('🎉', style: TextStyle(fontSize: 32)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('您的晚餐預約已建立', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: theme.colorScheme.onSurface.withOpacity(0.7))),
                const SizedBox(height: 8),
                Text('我們已發送通知給對方', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: chinguTheme?.surfaceVariant ?? theme.dividerColor),
                    boxShadow: [BoxShadow(color: chinguTheme?.shadowLight ?? Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.people_rounded, '6人晚餐聚會', theme.colorScheme.primary, theme),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.calendar_today_rounded, '2025/10/15 19:00', chinguTheme?.secondary ?? theme.colorScheme.secondary, theme),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.payments_rounded, 'NT\$ 500-800 / 人', chinguTheme?.success ?? Colors.green, theme),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.location_on_rounded, '台北市信義區', chinguTheme?.warning ?? Colors.orange, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
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
                    child: const Text('查看詳情', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: () {}, child: Text('返回首頁', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)))),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text, Color color, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Text(text, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
      ],
    );
  }
}
