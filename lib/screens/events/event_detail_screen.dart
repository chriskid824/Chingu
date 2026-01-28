import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
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
  final DinnerEventService _eventService = DinnerEventService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final userId = context.read<AuthProvider>().uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!;

        // Check user status
        final isParticipant = event.participantIds.contains(userId);
        final isWaitlisted = event.waitingListIds.contains(userId);
        final isFull = event.isFull;
        final isDeadlinePassed = DateTime.now().isAfter(event.registrationDeadline);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
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
                    onPressed: () {},
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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '6人晚餐聚會',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(context, event, isWaitlisted),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildInfoCard(
                        context,
                        Icons.calendar_today_rounded,
                        '日期時間',
                        DateFormat('yyyy/MM/dd (E)\nHH:mm').format(event.dateTime),
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
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '6 人（固定）\n目前已報名：${event.participantIds.length} 人\n候補：${event.waitingListIds.length} 人',
                        chinguTheme?.warning ?? Colors.orange,
                      ),
                      const SizedBox(height: 12),
                       _buildInfoCard(
                        context,
                        Icons.timer_rounded,
                        '報名截止',
                        DateFormat('yyyy/MM/dd HH:mm').format(event.registrationDeadline),
                        theme.colorScheme.error,
                      ),

                      if (isParticipant) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {},
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
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
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
              child: _buildActionButton(
                context,
                event,
                userId,
                isParticipant,
                isWaitlisted,
                isFull,
                isDeadlinePassed
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, DinnerEventModel event, bool isWaitlisted) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color color;
    String text;

    if (isWaitlisted) {
      color = chinguTheme?.warning ?? Colors.orange;
      text = '候補中';
    } else {
      switch (event.status) {
        case EventStatus.pending:
          color = chinguTheme?.warning ?? Colors.orange;
          text = '等待配對';
          break;
        case EventStatus.confirmed:
          color = chinguTheme?.success ?? Colors.green;
          text = '已確認';
          break;
        case EventStatus.completed:
          color = theme.colorScheme.onSurface.withOpacity(0.6);
          text = '已完成';
          break;
        case EventStatus.cancelled:
          color = theme.colorScheme.error;
          text = '已取消';
          break;
        case EventStatus.full:
          color = theme.colorScheme.secondary;
          text = '已額滿';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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

  Widget _buildActionButton(
    BuildContext context,
    DinnerEventModel event,
    String userId,
    bool isParticipant,
    bool isWaitlisted,
    bool isFull,
    bool isDeadlinePassed,
  ) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (event.status == EventStatus.completed || event.status == EventStatus.cancelled) {
      return const SizedBox.shrink(); // No actions for past events
    }

    if (isParticipant) {
      return OutlinedButton(
        onPressed: () => _showLeaveDialog(context, userId, false),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          '取消報名',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: () => _showLeaveDialog(context, userId, true),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(
          '取消排隊',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (isDeadlinePassed) {
       return Container(
         padding: const EdgeInsets.symmetric(vertical: 16),
         alignment: Alignment.center,
         decoration: BoxDecoration(
           color: theme.disabledColor,
           borderRadius: BorderRadius.circular(30),
         ),
         child: const Text(
           '報名已截止',
           style: TextStyle(
             color: Colors.white,
             fontSize: 16,
             fontWeight: FontWeight.bold,
           ),
         ),
       );
    }

    // Not joined, not deadline passed
    if (isFull) {
       return GradientButton(
        text: '加入候補 (Join Waitlist)',
        onPressed: () => _showJoinDialog(context, userId, true),
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _showJoinDialog(context, userId, false),
    );
  }

  void _showJoinDialog(BuildContext context, String userId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isWaitlist ? '加入候補名單？' : '確認報名？'),
        content: Text(isWaitlist
          ? '目前人數已滿，您將加入候補名單。若有名額釋出，將自動遞補。'
          : '確認報名此活動？報名後請準時出席。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleJoin(userId);
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _showLeaveDialog(BuildContext context, String userId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isWaitlist ? '取消候補？' : '取消報名？'),
        content: Text(isWaitlist
          ? '您確定要退出候補名單嗎？'
          : '活動開始前24小時內取消可能會扣除信用分數。您確定要取消嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _handleLeave(userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確定取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoin(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.joinEvent(widget.eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('報名成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('報名失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave(String userId) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(widget.eventId, userId);
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消失敗: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
