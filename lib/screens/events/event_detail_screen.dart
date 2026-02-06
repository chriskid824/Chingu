import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final DinnerEventService _eventService;
  late final Stream<DinnerEventModel?> _eventStream;

  @override
  void initState() {
    super.initState();
    _eventService = DinnerEventService();
    _eventStream = _eventService.getEventStream(widget.eventId);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              leading: const BackButton(),
            ),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            appBar: AppBar(
              leading: const BackButton(),
            ),
            body: const Center(child: Text('活動不存在')),
          );
        }

        return _EventDetailContent(event: event);
      },
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final DinnerEventModel event;

  const _EventDetailContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = context.watch<AuthProvider>().user;
    final userId = user?.uid;

    if (userId == null) return const SizedBox.shrink();

    final isParticipant = event.participantIds.contains(userId);
    final isWaitlisted = event.waitlistIds.contains(userId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, theme, chinguTheme, isParticipant, isWaitlisted),
                  const SizedBox(height: 24),
                  _buildInfoCards(context, theme, chinguTheme),
                  const SizedBox(height: 32),
                  if (isParticipant) _buildParticipantActions(context, theme, chinguTheme),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        theme,
        userId,
        isParticipant,
        isWaitlisted,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
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
            // Share implementation
          },
        ),
        const SizedBox(width: 8),
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

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ChinguTheme? chinguTheme,
    bool isParticipant,
    bool isWaitlisted,
  ) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isParticipant) {
      statusText = '已報名';
      statusColor = chinguTheme?.success ?? Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isWaitlisted) {
      statusText = '候補中';
      statusColor = chinguTheme?.warning ?? Colors.orange;
      statusIcon = Icons.hourglass_top;
    } else {
      switch (event.status) {
        case EventStatus.full:
          statusText = '已額滿';
          statusColor = chinguTheme?.warning ?? Colors.orange;
          statusIcon = Icons.people;
          break;
        case EventStatus.confirmed:
          statusText = '已確認';
          statusColor = chinguTheme?.success ?? Colors.green;
          statusIcon = Icons.check_circle;
          break;
        case EventStatus.completed:
          statusText = '已結束';
          statusColor = Colors.grey;
          statusIcon = Icons.event_available;
          break;
        case EventStatus.cancelled:
          statusText = '已取消';
          statusColor = Colors.red;
          statusIcon = Icons.cancel;
          break;
        case EventStatus.pending:
        default:
          statusText = '等待配對';
          statusColor = theme.colorScheme.primary;
          statusIcon = Icons.pending;
          break;
      }
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '6人晚餐聚會',
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
            border: Border.all(color: statusColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
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

  Widget _buildInfoCards(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');
    final dateStr = dateFormat.format(event.dateTime);

    final participantCountText = '${event.participantIds.length} 人 / 6 人';
    final waitlistCountText = event.waitlistIds.isNotEmpty
        ? ' (候補 ${event.waitlistIds.length} 人)'
        : '';

    return Column(
      children: [
        _buildInfoCard(
          context,
          Icons.calendar_today_rounded,
          '日期時間',
          dateStr,
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
          '${event.city}${event.district}',
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '$participantCountText$waitlistCountText',
          chinguTheme?.warning ?? Colors.orange,
        ),
        if (event.notes != null && event.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.note_rounded,
            '備註',
            event.notes!,
            Colors.grey,
          ),
        ],
      ],
    );
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

  Widget _buildParticipantActions(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Implement chat navigation
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
        // Navigation button removed as it was placeholder logic
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    String userId,
    bool isParticipant,
    bool isWaitlisted,
  ) {
    final isFull = event.status == EventStatus.full || event.participantIds.length >= 6;
    final isRegistrationClosed = DateTime.now().isAfter(event.registrationDeadline);
    final isCompletedOrCancelled = event.status == EventStatus.completed || event.status == EventStatus.cancelled;

    if (isCompletedOrCancelled) {
      return const SizedBox.shrink();
    }

    String buttonText = '立即報名';
    VoidCallback? onPressed;
    bool isDestructive = false;

    if (isParticipant) {
      buttonText = '取消報名';
      isDestructive = true;
      onPressed = () => _showCancelDialog(context, userId);
    } else if (isWaitlisted) {
      buttonText = '取消候補';
      isDestructive = true;
      onPressed = () => _showCancelDialog(context, userId);
    } else if (isRegistrationClosed) {
      buttonText = '報名已截止';
      onPressed = null;
    } else if (isFull) {
      buttonText = '加入候補名單';
      onPressed = () => _showJoinDialog(context, userId, isWaitlist: true);
    } else {
      buttonText = '立即報名';
      onPressed = () => _showJoinDialog(context, userId, isWaitlist: false);
    }

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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              )
            : GradientButton(
                text: buttonText,
                onPressed: onPressed,
              ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String userId, {required bool isWaitlist}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入候補' : '確認報名'),
        content: Text(isWaitlist
          ? '目前活動已額滿，是否加入候補名單？如果有空缺將會通知您。'
          : '確定要報名此活動嗎？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<DinnerEventProvider>();
              final success = await provider.joinEvent(event.id, userId);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? '操作失敗')),
                  );
                }
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消確認'),
        content: const Text('確定要取消嗎？如果是正式參加者，可能會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<DinnerEventProvider>();
              final success = await provider.leaveEvent(event.id, userId);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.errorMessage ?? '操作失敗')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }
}
