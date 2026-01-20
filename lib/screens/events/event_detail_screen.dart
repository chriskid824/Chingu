import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/enums/event_status.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final DinnerEventModel? initialEvent;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final DinnerEventService _eventService;

  @override
  void initState() {
    super.initState();
    _eventService = DinnerEventService();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(widget.eventId),
      initialData: widget.initialEvent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('錯誤')),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, event),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, event),
                      const SizedBox(height: 24),
                      _buildParticipantsSection(context, event, user.uid),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, event, user.uid),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, user.uid),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_rounded,
            size: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.share_rounded,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onPressed: () {
            // TODO: Implement share
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '🍽️',
                    style: TextStyle(fontSize: 40),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color statusColor;
    switch (event.status) {
      case EventStatus.confirmed:
        statusColor = chinguTheme?.success ?? Colors.green;
        break;
      case EventStatus.completed:
        statusColor = theme.colorScheme.primary;
        break;
      case EventStatus.cancelled:
        statusColor = theme.colorScheme.error;
        break;
      case EventStatus.pending:
      default:
        statusColor = chinguTheme?.warning ?? Colors.orange;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '${event.maxParticipants}人晚餐聚會',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                event.status.label,
                style: TextStyle(
                  fontSize: 13,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Column(
      children: [
        _buildInfoCard(
          context,
          Icons.calendar_today_rounded,
          '日期時間',
          DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW').format(event.dateTime),
          theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.payments_rounded,
          '預算範圍',
          '${event.budgetRangeText} / 人',
          theme.colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.location_on_rounded,
          '地點',
          '${event.city} ${event.district}\n${event.restaurantName ?? "餐廳待定"}',
          chinguTheme?.success ?? Colors.green,
        ),
        if (event.registrationDeadline != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.timer_outlined,
            '報名截止',
            DateFormat('MM/dd HH:mm').format(event.registrationDeadline!),
            Colors.orange,
          ),
        ],
      ],
    );
  }

  Widget _buildParticipantsSection(BuildContext context, DinnerEventModel event, String currentUserId) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final participantCount = event.participantIds.length;
    final maxParticipants = event.maxParticipants;
    final remainingSlots = maxParticipants - participantCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '參加成員',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$participantCount / $maxParticipants',
              style: theme.textTheme.titleMedium?.copyWith(
                color: remainingSlots > 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: participantCount / maxParticipants,
          backgroundColor: theme.disabledColor.withOpacity(0.2),
          color: remainingSlots > 0 ? theme.colorScheme.primary : chinguTheme?.success,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
        // 這裡未來可以展示具體用戶頭像，目前顯示數量
        Text(
          event.waitingList.isNotEmpty
              ? '候補名單：${event.waitingList.length} 人'
              : '目前無人候補',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DinnerEventModel event, String currentUserId) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final isParticipant = event.participantIds.contains(currentUserId);

    if (!isParticipant) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to chat
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '聊天',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (event.restaurantAddress != null) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: chinguTheme?.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate map
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '導航',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, String currentUserId) {
    final theme = Theme.of(context);
    final isParticipant = event.participantIds.contains(currentUserId);
    final isWaiting = event.waitingList.contains(currentUserId);
    final isFull = event.participantIds.length >= event.maxParticipants;
    final isCreator = event.creatorId == currentUserId;

    // 檢查是否過期
    final isExpired = event.dateTime.isBefore(DateTime.now());
    final isDeadlinePassed = event.registrationDeadline != null &&
                             DateTime.now().isAfter(event.registrationDeadline!);
    final isCancelled = event.status == EventStatus.cancelled;

    String buttonText;
    VoidCallback? onPressed;
    bool isDestructive = false;

    if (isCancelled) {
      buttonText = '活動已取消';
      onPressed = null;
    } else if (isExpired) {
      buttonText = '活動已結束';
      onPressed = null;
    } else if (isParticipant) {
      buttonText = '取消報名'; // 或 "退出活動"
      onPressed = () => _showLeaveConfirmation(context, event);
      isDestructive = true;
    } else if (isWaiting) {
      buttonText = '取消候補';
      onPressed = () => _showLeaveConfirmation(context, event);
      isDestructive = true;
    } else if (isDeadlinePassed) {
      buttonText = '報名已截止';
      onPressed = null;
    } else if (isFull) {
      buttonText = '加入候補名單';
      onPressed = () => _showJoinConfirmation(context, event, isWaitlist: true);
    } else {
      buttonText = '立即報名';
      onPressed = () => _showJoinConfirmation(context, event, isWaitlist: false);
    }

    // 如果是創建者且活動未開始，可以取消活動（但這裡我們用退出代替，或者顯示額外按鈕）
    // 目前簡單處理：創建者也可以退出，退出後如果有候補會自動遞補

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: isDestructive
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            )
          : GradientButton(
              text: buttonText,
              onPressed: onPressed,
              isEnabled: onPressed != null,
            ),
      ),
    );
  }

  Future<void> _showJoinConfirmation(BuildContext context, DinnerEventModel event, {required bool isWaitlist}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入候補名單' : '確認報名'),
        content: Text(isWaitlist
          ? '目前活動已滿，確認要加入候補名單嗎？如有空位將自動遞補。'
          : '確認要參加此晚餐聚會嗎？報名後請務必準時出席。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<DinnerEventProvider>();
        final authProvider = context.read<AuthProvider>();

        await provider.joinEvent(event.id, authProvider.user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功！')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _showLeaveConfirmation(BuildContext context, DinnerEventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認退出'),
        content: const Text('確認要退出此活動嗎？如果有信用點數機制，可能會被扣除點數。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認退出'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final provider = context.read<DinnerEventProvider>();
        final authProvider = context.read<AuthProvider>();

        await provider.leaveEvent(event.id, authProvider.user!.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已退出活動')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失敗: $e')),
          );
        }
      }
    }
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
