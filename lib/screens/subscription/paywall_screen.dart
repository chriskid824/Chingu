import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/providers/subscription_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/subscription_model.dart';

/// 付費牆 — 免費次數用完後顯示
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text(
          '升級方案',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          color: AppColorsMinimal.textPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  const Text(
                    '解鎖無限晚餐體驗',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '智能配對 · 性別平衡 · 每週新朋友',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Plans
            _PlanCard(
              title: '單次票',
              price: 'NT\$149',
              subtitle: '體驗一次晚餐',
              icon: Icons.confirmation_num_rounded,
              color: AppColorsMinimal.textSecondary,
              plan: SubscriptionPlan.single,
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: '月票',
              price: 'NT\$399/月',
              subtitle: '每週一場，每場約 NT\$100',
              icon: Icons.calendar_month_rounded,
              color: AppColorsMinimal.primary,
              plan: SubscriptionPlan.monthly,
              badge: '最熱門',
            ),
            const SizedBox(height: 12),
            _PlanCard(
              title: '季票',
              price: 'NT\$999/季',
              subtitle: '最優惠！每場約 NT\$83',
              icon: Icons.diamond_rounded,
              color: AppColorsMinimal.warning,
              plan: SubscriptionPlan.quarterly,
              badge: '最省錢',
            ),

            const SizedBox(height: 24),

            // Features
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColorsMinimal.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColorsMinimal.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '付費包含什麼？',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColorsMinimal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _featureRow('🧠', '智能配對演算法，拒絕隨機亂分'),
                  _featureRow('👫', '性別平衡 3:3，品質保證'),
                  _featureRow('🏠', '精選餐廳，符合預算'),
                  _featureRow('💬', '配對成功可解鎖聊天'),
                  _featureRow('🔒', '匿名保護，安心參加'),
                  const SizedBox(height: 12),
                  Text(
                    '＊ 餐費各付各的，App 僅收取媒合費',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColorsMinimal.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cancellation policy
            Text(
              '活動取消 → 自動延長有效期或退回票券',
              style: TextStyle(
                fontSize: 12,
                color: AppColorsMinimal.textTertiary,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static Widget _featureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(
              fontSize: 13,
              color: AppColorsMinimal.textSecondary,
            )),
          ),
        ],
      ),
    );
  }
}

/// 方案卡片
class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final IconData icon;
  final Color color;
  final SubscriptionPlan plan;
  final String? badge;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.plan,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handlePurchase(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge != null ? color : AppColorsMinimal.surfaceVariant,
            width: badge != null ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColorsMinimal.shadowLight,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColorsMinimal.textPrimary,
                      )),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(badge!, style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          )),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(
                    fontSize: 12,
                    color: AppColorsMinimal.textTertiary,
                  )),
                ],
              ),
            ),
            Text(price, style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context) async {
    final provider = context.read<SubscriptionProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;
    if (userId == null) return;

    // 確認購買對話框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('確認購買 $title？'),
        content: Text('$price\n\n$subtitle'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsMinimal.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await provider.purchasePlan(userId, plan);

    if (!context.mounted) return;
    Navigator.pop(context); // 關閉付費牆
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已購買 $title！')),
    );
  }
}
