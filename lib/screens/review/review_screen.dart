import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/routes/app_router.dart';
import 'package:chingu/providers/review_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/user_model.dart';

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(
          color: isYes
              ? AppColorsMinimal.primary
              : isNo
                  ? AppColorsMinimal.divider
                  : AppColorsMinimal.surfaceVariant,
          width: isYes ? 2 : 1,
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
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColorsMinimal.primaryBackground,
            backgroundImage: user.avatarUrl != null
                ? CachedNetworkImageProvider(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColorsMinimal.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Name & info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColorsMinimal.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.age} 歲 · ${user.job}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColorsMinimal.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 想再見面
              _buildChoiceButton(
                icon: Icons.favorite_rounded,
                label: '想見面',
                isSelected: isYes,
                selectedColor: AppColorsMinimal.error,
                onTap: () => provider.setReviewChoice(user.uid, 'like'),
              ),
              const SizedBox(width: 8),
              // 下次再說
              _buildChoiceButton(
                icon: Icons.close_rounded,
                label: '下次',
                isSelected: isNo,
                selectedColor: AppColorsMinimal.textTertiary,
                onTap: () => provider.setReviewChoice(user.uid, 'dislike'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
        splashColor: selectedColor.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.1)
                : Colors.transparent, // 讓底下 Material 的水波紋可以被看見
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusSM),
            border: Border.all(
              color: isSelected ? selectedColor : AppColorsMinimal.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? selectedColor : AppColorsMinimal.textTertiary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? selectedColor : AppColorsMinimal.textTertiary,
                ),
              ),
            ],
          ),
        ),
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
