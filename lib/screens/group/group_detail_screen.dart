import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_colors_minimal.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_group_model.dart';
import 'package:chingu/providers/dinner_group_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/core/routes/app_router.dart';

/// 群組詳情頁 — 根據狀態顯示不同內容
class GroupDetailScreen extends StatefulWidget {
  final DinnerGroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Stream<DateTime> _tickStream;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _tickStream = Stream.periodic(
      const Duration(seconds: 60),
      (_) => DateTime.now(),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chinguTheme = Theme.of(context).extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: AppColorsMinimal.background,
      appBar: AppBar(
        backgroundColor: AppColorsMinimal.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppColorsMinimal.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '晚餐群組',
          style: TextStyle(
            color: AppColorsMinimal.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DinnerGroupModel?>(
        stream: context
            .read<DinnerGroupProvider>()
            .watchGroup(widget.group.id),
        initialData: widget.group,
        builder: (context, snapshot) {
          final group = snapshot.data ?? widget.group;

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 狀態標題
                  _buildStatusHeader(group, chinguTheme),
                  const SizedBox(height: AppColorsMinimal.spaceXL),

                  // 根據狀態顯示不同內容
                  if (group.status == 'pending')
                    _buildPendingContent(group, chinguTheme),
                  if (group.status == 'info_revealed')
                    _buildInfoRevealedContent(group, chinguTheme),
                  if (group.status == 'location_revealed')
                    _buildLocationRevealedContent(group, chinguTheme),
                  if (group.status == 'completed')
                    _buildCompletedContent(group, chinguTheme),

                  const SizedBox(height: AppColorsMinimal.spaceXL),

                  // 破冰問題（info_revealed 及之後顯示）
                  if (group.status != 'pending' &&
                      group.icebreakerQuestions.isNotEmpty)
                    _buildIcebreakerSection(group),

                  const SizedBox(height: AppColorsMinimal.spaceXL),

                  // 用餐須知（location_revealed 時顯示）
                  if (group.status == 'location_revealed')
                    _buildDiningInfoSection(),

                  // 配對說明（只在 pending 狀態顯示，等待時閱讀）
                  if (group.status == 'pending')
                    _buildMatchingExplanation(),

                  const SizedBox(height: AppColorsMinimal.space3XL),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── 狀態標題 ───
  Widget _buildStatusHeader(DinnerGroupModel group, ChinguTheme? theme) {
    final statusConfig = _getStatusConfig(group.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: theme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: (statusConfig['color'] as Color).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: (statusConfig['color'] as Color).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusConfig['icon'] as IconData,
              color: statusConfig['color'] as Color,
              size: 28,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceMD),
          Text(
            statusConfig['title'] as String,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const SizedBox(height: AppColorsMinimal.spaceXS),
          Text(
            statusConfig['subtitle'] as String,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColorsMinimal.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'pending':
        return {
          'icon': Icons.hourglass_top_rounded,
          'title': '⏳ 等待揭曉',
          'subtitle': '同伴資訊將於明天早上 10:00 揭曉',
          'color': AppColorsMinimal.warning,
        };
      case 'info_revealed':
        return {
          'icon': Icons.people_rounded,
          'title': '👀 同伴已揭曉！',
          'subtitle': '看看你的同桌夥伴，記得確認出席',
          'color': AppColorsMinimal.primary,
        };
      case 'location_revealed':
        return {
          'icon': Icons.restaurant_rounded,
          'title': '🎉 餐廳已揭曉！',
          'subtitle': '準備好和新朋友共進晚餐吧',
          'color': AppColorsMinimal.success,
        };
      case 'completed':
        return {
          'icon': Icons.check_circle_rounded,
          'title': '✅ 晚餐結束',
          'subtitle': '別忘了評價你的同桌夥伴',
          'color': AppColorsMinimal.success,
        };
      default:
        return {
          'icon': Icons.help_rounded,
          'title': '未知狀態',
          'subtitle': '',
          'color': AppColorsMinimal.textTertiary,
        };
    }
  }

  // ─── Pending 狀態 ───
  Widget _buildPendingContent(DinnerGroupModel group, ChinguTheme? theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 倒數（到週三 10:00）
        _buildCountdownToReveal(),
        const SizedBox(height: AppColorsMinimal.spaceLG),
        // 人數顯示
        _buildParticipantCount(group),
      ],
    );
  }

  Widget _buildCountdownToReveal() {
    return StreamBuilder<DateTime>(
      stream: _tickStream,
      builder: (context, _) {
        // 計算到下一個週三 10:00 的倒數
        final now = DateTime.now();
        var target = DateTime(now.year, now.month, now.day, 10, 0);
        while (target.weekday != DateTime.wednesday || target.isBefore(now)) {
          target = target.add(const Duration(days: 1));
        }
        final diff = target.difference(now);
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
          decoration: BoxDecoration(
            color: AppColorsMinimal.surface,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            border: Border.all(color: AppColorsMinimal.surfaceVariant),
          ),
          child: Column(
            children: [
              Text(
                '同伴揭曉倒數',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColorsMinimal.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppColorsMinimal.spaceMD),
              Text(
                '${hours}h ${minutes}m',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w800,
                  color: AppColorsMinimal.primary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Info Revealed 狀態 ───
  Widget _buildInfoRevealedContent(
      DinnerGroupModel group, ChinguTheme? theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 出席確認按鈕
        _buildAttendanceButton(group),
        const SizedBox(height: AppColorsMinimal.spaceXL),
        // 出席狀態列
        _buildAttendanceStatus(group),
        const SizedBox(height: AppColorsMinimal.spaceXL),
        // 同伴卡片
        _buildSectionLabel('你的同桌夥伴'),
        const SizedBox(height: AppColorsMinimal.spaceMD),
        ...group.companionPreviews.map((preview) =>
            _buildCompanionCard(preview)),
      ],
    );
  }

  bool _isConfirmingAttendance = false;

  Widget _buildAttendanceButton(DinnerGroupModel group) {
    final userId = context.read<AuthProvider>().uid ?? '';
    final confirmed = group.attendanceConfirmed[userId] ?? false;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (confirmed || _isConfirmingAttendance)
            ? null
            : () async {
                setState(() => _isConfirmingAttendance = true);
                try {
                  await context
                      .read<DinnerGroupProvider>()
                      .confirmAttendance(group.id, userId);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('確認失敗: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isConfirmingAttendance = false);
                }
              },
        icon: _isConfirmingAttendance
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(confirmed ? Icons.check_circle : Icons.check_circle_outline),
        label: Text(
          _isConfirmingAttendance ? '確認中...' : (confirmed ? '已確認出席 ✅' : '確認出席'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              confirmed ? AppColorsMinimal.success : AppColorsMinimal.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _isConfirmingAttendance 
              ? AppColorsMinimal.primary.withValues(alpha: 0.7) 
              : AppColorsMinimal.success.withValues(alpha: 0.8),
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(DinnerGroupModel group) {
    final total = group.participantIds.length;
    final confirmed =
        group.attendanceConfirmed.values.where((v) => v).length;

    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded,
              color: AppColorsMinimal.primary, size: 20),
          const SizedBox(width: AppColorsMinimal.spaceSM),
          Text(
            '出席確認',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: confirmed == total
                  ? AppColorsMinimal.success.withValues(alpha: 0.12)
                  : AppColorsMinimal.warning.withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(AppColorsMinimal.radiusFull),
            ),
            child: Text(
              '$confirmed / $total 人已確認',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: confirmed == total
                    ? AppColorsMinimal.success
                    : AppColorsMinimal.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 同伴卡片差異化顏色
  static const _companionColors = [
    Color(0xFF7C4DFF), // 紫
    Color(0xFFFF6D00), // 橘
    Color(0xFF00BFA5), // 綠
    Color(0xFFE91E63), // 粉
    Color(0xFF2962FF), // 藍
    Color(0xFFFFAB00), // 金
  ];

  Widget _buildCompanionCard(Map<String, dynamic> preview) {
    final zodiac = preview['zodiac'] ?? '尚未設定';
    final industry = preview['industryCategory'] ?? '其他';
    final ageGroup = preview['ageGroup'] ?? '';
    final interests = List<String>.from(preview['topInterests'] ?? []);
    final nationality = preview['nationality'] ?? '';
    final index = preview['index'] as int? ?? 0;
    final cardColor = _companionColors[index % _companionColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
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
      child: Row(
        children: [
          // 匿名頭像（使用差異化顏色）
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_rounded,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppColorsMinimal.spaceLG),
          // 資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      zodiac,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    if (nationality.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        nationality,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColorsMinimal.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$industry · $ageGroup',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColorsMinimal.textSecondary,
                  ),
                ),
                if (interests.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: interests
                        .map((interest) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColorsMinimal.primaryBackground,
                                borderRadius: BorderRadius.circular(
                                    AppColorsMinimal.radiusFull),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColorsMinimal.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Location Revealed 狀態 ───
  Widget _buildLocationRevealedContent(
      DinnerGroupModel group, ChinguTheme? theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 餐廳資訊卡
        _buildRestaurantCard(group, theme),
        const SizedBox(height: AppColorsMinimal.spaceXL),
        // 出席狀態
        _buildAttendanceStatus(group),
        const SizedBox(height: AppColorsMinimal.spaceXL),
        // 同伴卡片
        _buildSectionLabel('你的同桌夥伴'),
        const SizedBox(height: AppColorsMinimal.spaceMD),
        ...group.companionPreviews.map((preview) =>
            _buildCompanionCard(preview)),
      ],
    );
  }

  Widget _buildRestaurantCard(DinnerGroupModel group, ChinguTheme? theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppColorsMinimal.spaceXL),
      decoration: BoxDecoration(
        gradient: theme?.transparentGradient,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusLG),
        border: Border.all(
          color: AppColorsMinimal.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColorsMinimal.success.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppColorsMinimal.radiusSM),
                ),
                child: Icon(Icons.restaurant_rounded,
                    color: AppColorsMinimal.success, size: 24),
              ),
              const SizedBox(width: AppColorsMinimal.spaceMD),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.restaurantName ?? '驚喜餐廳',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColorsMinimal.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.restaurantAddress ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColorsMinimal.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.restaurantPhone != null &&
              group.restaurantPhone!.isNotEmpty) ...[
            const SizedBox(height: AppColorsMinimal.spaceLG),
            Row(
              children: [
                Icon(Icons.phone_rounded,
                    size: 16, color: AppColorsMinimal.textTertiary),
                const SizedBox(width: 6),
                Text(
                  group.restaurantPhone!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColorsMinimal.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Completed 狀態 ───
  Widget _buildCompletedContent(DinnerGroupModel group, ChinguTheme? theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.review,
                arguments: {'group': group},
              );
            },
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text(
              '前往評價 ✨',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsMinimal.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppColorsMinimal.radiusMD),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: AppColorsMinimal.spaceXL),
        // 餐廳回顧
        if (group.restaurantName != null)
          _buildRestaurantCard(group, theme),
      ],
    );
  }

  // ─── 破冰問題 ───
  Widget _buildIcebreakerSection(DinnerGroupModel group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('💬 今晚的破冰話題'),
        const SizedBox(height: AppColorsMinimal.spaceMD),
        ...group.icebreakerQuestions.asMap().entries.map(
              (entry) => Container(
                margin:
                    const EdgeInsets.only(bottom: AppColorsMinimal.spaceMD),
                padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
                decoration: BoxDecoration(
                  color: AppColorsMinimal.surface,
                  borderRadius:
                      BorderRadius.circular(AppColorsMinimal.radiusMD),
                  border: Border.all(color: AppColorsMinimal.surfaceVariant),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColorsMinimal.primary
                            .withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColorsMinimal.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppColorsMinimal.spaceMD),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColorsMinimal.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  // ─── 共用元件 ───
  Widget _buildParticipantCount(DinnerGroupModel group) {
    return Container(
      padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
      decoration: BoxDecoration(
        color: AppColorsMinimal.surface,
        borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
        border: Border.all(color: AppColorsMinimal.surfaceVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.group_rounded,
              color: AppColorsMinimal.primary, size: 20),
          const SizedBox(width: AppColorsMinimal.spaceSM),
          Text(
            '${group.participantIds.length} 人同桌',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColorsMinimal.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            '身份保密中 🔒',
            style: TextStyle(
              fontSize: 12,
              color: AppColorsMinimal.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: AppColorsMinimal.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppColorsMinimal.spaceSM),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColorsMinimal.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── 用餐須知 ───
  Widget _buildDiningInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppColorsMinimal.spaceXL),
        _buildSectionLabel('🍽️ 用餐須知'),
        const SizedBox(height: AppColorsMinimal.spaceMD),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
          decoration: BoxDecoration(
            color: AppColorsMinimal.surface,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
            border: Border.all(color: AppColorsMinimal.surfaceVariant),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.payments_rounded, '費用方式',
                  '採各付各的（Go Dutch）\nApp 不收取餐費，你只需支付自己的餐點'),
              _buildDivider(),
              _buildInfoRow(Icons.account_balance_wallet_rounded, '預算範圍',
                  '系統已根據同桌 6 人的偏好選擇餐廳\n請放心，價位符合大家的預算'),
              _buildDivider(),
              _buildInfoRow(Icons.restaurant_menu_rounded, '飲食注意',
                  '特殊飲食需求已在配對時納入考量\n抵達餐廳後仍可自由點餐'),
              _buildDivider(),
              _buildInfoRow(Icons.schedule_rounded, '時間禮儀',
                  '請準時於 19:00 抵達\n如遲到請提前通知同桌夥伴'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppColorsMinimal.spaceSM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColorsMinimal.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColorsMinimal.primary, size: 16),
          ),
          const SizedBox(width: AppColorsMinimal.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: AppColorsMinimal.textPrimary,
                )),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(
                  fontSize: 12, color: AppColorsMinimal.textSecondary,
                  height: 1.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: AppColorsMinimal.surfaceVariant,
      height: AppColorsMinimal.spaceMD,
    );
  }

  // ─── 配對說明（只在 pending 顯示） ───
  Widget _buildMatchingExplanation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppColorsMinimal.spaceXL),
        _buildSectionLabel('🧠 我們如何配對？'),
        const SizedBox(height: AppColorsMinimal.spaceMD),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppColorsMinimal.spaceLG),
          decoration: BoxDecoration(
            color: AppColorsMinimal.primaryBackground,
            borderRadius: BorderRadius.circular(AppColorsMinimal.radiusMD),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chingu 不是隨機亂分！',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppColorsMinimal.textPrimary,
                ),
              ),
              const SizedBox(height: AppColorsMinimal.spaceMD),
              _buildMatchingPoint('👫', '性別平衡', '盡可能男女 3:3'),
              _buildMatchingPoint('🎯', '興趣相容', '共同興趣越多，配對分數越高'),
              _buildMatchingPoint('🎂', '年齡相近', '優先配對年齡層接近的夥伴'),
              _buildMatchingPoint('💰', '預算一致', '確保大家對餐廳價位有共識'),
              const SizedBox(height: AppColorsMinimal.spaceSM),
              Text(
                '每一桌都經過 50 次優化運算 ✨',
                style: TextStyle(
                  fontSize: 12, color: AppColorsMinimal.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingPoint(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text('$title — ', style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600,
            color: AppColorsMinimal.textPrimary,
          )),
          Expanded(
            child: Text(desc, style: TextStyle(
              fontSize: 13, color: AppColorsMinimal.textSecondary,
            )),
          ),
        ],
      ),
    );
  }
}
