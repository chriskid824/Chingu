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
    bool? choice,
    ReviewProvider provider,
  ) {
    final isYes = choice == true;
    final isNo = choice == false;

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
                onTap: () => provider.setReviewChoice(user.uid, true),
              ),
              const SizedBox(width: 8),
              // 下次再說
              _buildChoiceButton(
                icon: Icons.close_rounded,
                label: '下次',
                isSelected: isNo,
                selectedColor: AppColorsMinimal.textTertiary,
                onTap: () => provider.setReviewChoice(user.uid, false),
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

    // Step 2: 顯示體驗回饋
    final shouldContinue = await _showExperienceFeedback(provider, group);
    if (!mounted || !shouldContinue) return;

    // Step 3: 顯示結果
    if (provider.newChatRoomIds.isNotEmpty) {
      _showMutualMatchDialog(provider.newChatRoomIds.length);
    } else {
      _showCompletionDialog();
    }
  }

  Future<bool> _showExperienceFeedback(
      ReviewProvider provider, Map<String, dynamic> group) async {
    final dinnerCount = group['dinnerCount'] as int? ?? 1;

    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          builder: (ctx) => _ExperienceFeedbackSheet(
            provider: provider,
            showPreference: dinnerCount >= 3,
          ),
        ) ??
        true;
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

// ─── 體驗回饋 BottomSheet ───
class _ExperienceFeedbackSheet extends StatelessWidget {
  final ReviewProvider provider;
  final bool showPreference;

  const _ExperienceFeedbackSheet({
    required this.provider,
    required this.showPreference,
  });

  static const _emojis = ['😐', '🙂', '😊', '😄', '🤩'];
  static const _highlights = [
    '聊天很投緣',
    '話題很有趣',
    '氣氛很輕鬆',
    '餐廳環境好',
  ];
  static const _preferences = [
    '🔥 想認識完全不同領域的人',
    '🤝 想認識有共同興趣的人',
    '🎲 交給 Chingu 決定！',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListenableBuilder(
        listenable: provider,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              '這次體驗如何？',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '你的回饋會幫助我們更懂你',
              style: TextStyle(
                fontSize: 13, color: AppColorsMinimal.textTertiary,
              ),
            ),
            const SizedBox(height: 24),

            // Emoji slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final selected = provider.experienceRating == i + 1;
                return GestureDetector(
                  onTap: () => provider.setExperienceRating(i + 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColorsMinimal.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? AppColorsMinimal.primary
                            : AppColorsMinimal.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      _emojis[i],
                      style: TextStyle(fontSize: selected ? 32 : 24),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Highlights
            const Text(
              '你最喜歡這次的什麼？',
              style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: AppColorsMinimal.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _highlights.map((h) {
                final selected = provider.experienceHighlights.contains(h);
                return GestureDetector(
                  onTap: () => provider.toggleHighlight(h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColorsMinimal.primary
                          : AppColorsMinimal.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColorsMinimal.primary
                            : AppColorsMinimal.divider,
                      ),
                    ),
                    child: Text(
                      h,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? Colors.white : AppColorsMinimal.textPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Preference (≥3 dinners)
            if (showPreference) ...[
              const SizedBox(height: 24),
              const Text(
                '下次想認識什麼樣的人？',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._preferences.map((p) {
                final selected = provider.preferenceForNext == p;
                return GestureDetector(
                  onTap: () => provider.setPreferenceForNext(
                      selected ? null : p),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColorsMinimal.primaryBackground
                          : AppColorsMinimal.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColorsMinimal.primary
                            : AppColorsMinimal.divider,
                      ),
                    ),
                    child: Text(
                      p,
                      style: TextStyle(
                        fontSize: 14,
                        color: selected
                            ? AppColorsMinimal.primary
                            : AppColorsMinimal.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: provider.experienceRating != null
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsMinimal.primary,
                  disabledBackgroundColor: AppColorsMinimal.surfaceDisabled,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '送出回饋 ✨',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
