import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_animations.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/widgets/geometric_avatar.dart';

/// 評價畫面 — 晚餐後對同桌成員做互評
///
/// arguments: { 'group': Map<String, dynamic> } from getPendingReviewGroups
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final args = ModalRoute.of(context)?.settings.arguments
          as Map<String, dynamic>?;
      if (args != null && args['group'] != null) {
        final reviewProvider = context.read<ReviewProvider>();
        reviewProvider.loadRevieweesForGroup(args['group']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        title: const Text(
          '互相評價',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColorsMinimal.textPrimary,
        ),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.pendingReviewees.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColorsMinimal.primary,
              ),
            );
          }

          if (provider.pendingReviewees.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              // Header hint
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColorsMinimal.transparentGradient,
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                  border: Border.all(color: AppColorsMinimal.primaryBackground),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.primaryBackground,
                        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColorsMinimal.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '選擇想再見面的人\n雙方都選「想再見面」就能解鎖聊天！',
                        style: TextStyle(
                          color: AppColorsMinimal.textSecondary,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Reviewee list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.pendingReviewees.length,
                  itemBuilder: (context, index) {
                    final user = provider.pendingReviewees[index];
                    final choice = provider.reviewChoices[user.uid];
                    return _buildRevieweeCard(user, choice, provider);
                  },
                ),
              ),

              // Submit button
              _buildSubmitButton(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppColorsMinimal.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '沒有待評價的人',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您已完成所有評價',
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevieweeCard(
    UserModel user,
    String? choice,
    ReviewProvider provider,
  ) {
    final isYes = choice == 'like';
    final isNo = choice == 'dislike';

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceLG),
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: isYes
              ? AppColorsMinimal.secondary
              : isNo
                  ? AppColorsMinimal.divider
                  : AppColorsMinimal.surfaceVariant,
          width: isYes ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColorsMinimal.shadowLight,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 人物資訊
          Row(
            children: [
              GeometricAvatar(
                seed: user.uid,
                photoUrl: user.avatarUrl,
                showPhoto: PhotoVisibility.isReviewPhotoVisible(),
                size: 64,
                name: user.name,
              ),
              const SizedBox(width: AppColorsMinimal.spaceLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppColorsMinimal.spaceXS),
                    Text(
                      '${user.age} 歲 · ${user.job}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColorsMinimal.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppColorsMinimal.spaceXL),

          // 操作按鈕 — 兩個大圓形按鈕並排
          Row(
            children: [
              Expanded(
                child: _ReviewChoiceButton(
                  icon: Icons.close_rounded,
                  label: '下次再說',
                  isSelected: isNo,
                  baseColor: AppColorsMinimal.textTertiary,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    provider.setReviewChoice(user.uid, 'dislike');
                  },
                ),
              ),
              const SizedBox(width: AppColorsMinimal.spaceLG),
              Expanded(
                child: _ReviewChoiceButton(
                  icon: Icons.favorite_rounded,
                  label: '想再見面',
                  isSelected: isYes,
                  baseColor: AppColorsMinimal.secondary,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    provider.setReviewChoice(user.uid, 'like');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ReviewProvider provider) {
    final allCompleted = provider.allReviewsCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColorsMinimal.shadowMedium,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: allCompleted && !provider.isLoading
                ? () => _handleSubmit(provider)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsMinimal.primary,
              disabledBackgroundColor: AppColorsMinimal.surfaceDisabled,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
              ),
              elevation: 0,
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    allCompleted
                        ? '提交評價 (${provider.reviewChoices.length}/${provider.pendingReviewees.length})'
                        : '請完成所有評價',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit(ReviewProvider provider) async {
    final args = ModalRoute.of(context)?.settings.arguments
        as Map<String, dynamic>?;
    final group = args?['group'] as Map<String, dynamic>?;
    if (group == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.uid;
    if (userId == null) return;

    // Step 1: 提交互評
    await provider.submitAllReviews(
      reviewerId: userId,
      groupId: group['groupId'],
      eventId: group['eventId'],
    );

    if (!mounted) return;

    // 顯示結果
    if (provider.newChatRoomIds.isNotEmpty) {
      _showMutualMatchDialog(provider.newChatRoomIds.length);
    } else {
      _showCompletionDialog();
    }
  }

  void _showMutualMatchDialog(int matchCount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: AppColorsMinimal.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 配對成功！',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '有 $matchCount 位也想再見面！\n聊天室已解鎖',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.mainNavigation,
                  (route) => false,
                  arguments: {'initialIndex': 1}, // 跳到聊天 Tab
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                '去聊天 💬',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColorsMinimal.successLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 40,
                color: AppColorsMinimal.success,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '評價完成',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '感謝您的回饋！\n下次晚餐見 👋',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColorsMinimal.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // 回到首頁
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsMinimal.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: const Text(
                '返回首頁',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 評價選擇按鈕 — 大尺寸 + 回彈動畫 + Haptic
class _ReviewChoiceButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color baseColor;
  final VoidCallback onTap;

  const _ReviewChoiceButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.baseColor,
    required this.onTap,
  });

  @override
  State<_ReviewChoiceButton> createState() => _ReviewChoiceButtonState();
}

class _ReviewChoiceButtonState extends State<_ReviewChoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.bounceButton,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: AppAnimations.bounceScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.bounceCurve,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final color = widget.baseColor;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppColorsMinimal.spaceLG),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColorsMinimal.surfaceVariant,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            border: Border.all(
              color: isSelected ? color : AppColorsMinimal.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 52 : 44,
                height: isSelected ? 52 : 44,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  size: isSelected ? 28 : 24,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: AppColorsMinimal.spaceSM),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? color : AppColorsMinimal.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
