import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: DinnerEventService().getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('錯誤')),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('活動不存在')),
            body: const Center(child: Text('找不到此活動')),
          );
        }

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
                      _buildHeader(context, event, chinguTheme),
                      const SizedBox(height: 24),
                      _buildInfoCards(context, event, chinguTheme, theme),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, event, theme, chinguTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, userId, theme),
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
            // TODO: Share event
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
                  Text(
                    event.city,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme) {
    final theme = Theme.of(context);

    Color statusColor;
    IconData statusIcon;

    switch (event.status) {
      case EventStatus.confirmed:
        statusColor = chinguTheme?.success ?? Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case EventStatus.cancelled:
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.cancel;
        break;
      case EventStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.task_alt;
        break;
      case EventStatus.pending:
      default:
        statusColor = chinguTheme?.warning ?? Colors.orange;
        statusIcon = Icons.hourglass_empty;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '${event.budgetRangeText} 晚餐聚會',
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
                event.statusText,
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

  Widget _buildInfoCards(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme, ThemeData theme) {
    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');

    return Column(
      children: [
        _buildInfoCard(
          context,
          Icons.calendar_today_rounded,
          '日期時間',
          dateFormat.format(event.dateTime),
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
          '${event.city} ${event.district}',
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '6 人（固定）\n目前已確認：${event.participantIds.length} 人\n等候名單：${event.waitlist.length} 人',
          chinguTheme?.warning ?? Colors.orange,
        ),
        if (event.notes != null && event.notes!.isNotEmpty) ...[
           const SizedBox(height: 12),
           _buildInfoCard(
            context,
            Icons.note_alt_rounded,
            '備註',
            event.notes!,
            Colors.grey,
          ),
        ]
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

  Widget _buildActionButtons(BuildContext context, DinnerEventModel event, ThemeData theme, ChinguTheme? chinguTheme) {
    // Only show extra actions if user is a participant
    // For now, these are placeholders or could be Chat/Navigation if confirmed
    if (event.status == EventStatus.confirmed) {
       return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                // TODO: Navigate to Chat
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
                   // TODO: Navigation logic
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
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, String userId, ThemeData theme) {
    final isParticipant = event.participantIds.contains(userId);
    final isWaitlisted = event.isWaitlisted(userId);
    final isFull = event.isFull;
    final isCancelled = event.status == EventStatus.cancelled;
    final isCompleted = event.status == EventStatus.completed;
    final isExpired = event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!);

    if (isCancelled || isCompleted) {
       return Container(
        padding: const EdgeInsets.all(24),
        color: theme.cardColor,
        child: Text(
          isCancelled ? '活動已取消' : '活動已結束',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
        ),
       );
    }

    String buttonText;
    VoidCallback onPressed;
    LinearGradient? gradient;

    if (isParticipant) {
      buttonText = '取消報名';
      gradient = const LinearGradient(colors: [Colors.redAccent, Colors.red]);
      onPressed = () => _showLeaveDialog(context, event.id, false);
    } else if (isWaitlisted) {
      buttonText = '退出等候名單';
      gradient = const LinearGradient(colors: [Colors.redAccent, Colors.red]);
      onPressed = () => _showLeaveDialog(context, event.id, true);
    } else if (isExpired) {
      // Disabled state rendered differently
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.cardColor),
        child: SafeArea(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: theme.disabledColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text(
              '報名已截止',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    } else if (isFull) {
      buttonText = '加入等候名單';
      onPressed = () => _showJoinDialog(context, event.id, true);
    } else {
      buttonText = '立即報名';
      onPressed = () => _showJoinDialog(context, event.id, false);
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
        child: GradientButton(
          text: buttonText,
          onPressed: onPressed,
          gradient: gradient,
        ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String eventId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入等候名單' : '確認報名'),
        content: Text(isWaitlist
            ? '目前活動已滿，是否加入等候名單？若有空位將自動遞補。'
            : '確定要參加這場晚餐聚會嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('再考慮'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await DinnerEventService().joinEvent(eventId, authProvider.uid!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已加入等候名單' : '報名成功！')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: $e')),
                  );
                }
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, String eventId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '退出等候名單' : '取消報名'),
        content: Text(isWaitlist
            ? '確定要退出等候名單嗎？'
            : '確定要取消報名嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('保留'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await DinnerEventService().leaveEvent(eventId, authProvider.uid!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: $e')),
                  );
                }
              }
            },
            child: const Text('確定退出'),
          ),
        ],
      ),
    );
  }
}
