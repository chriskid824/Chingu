import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_button.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  final DinnerEventModel? initialEvent;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DinnerEventModel?>(
      stream: DinnerEventService().getEventStream(eventId),
      initialData: initialEvent,
      builder: (context, snapshot) {
        final theme = Theme.of(context);

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('活動詳情')),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
           return Scaffold(
            appBar: AppBar(title: const Text('活動詳情')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('活動詳情')),
            body: const Center(child: Text('找不到活動')),
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

    if (userId == null) return const SizedBox();

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
              const SizedBox(width: 8),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
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
                      _buildStatusBadge(context, event.status),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
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
                    event.restaurantName ?? '${event.city} ${event.district}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildParticipantsCard(context, event, theme, chinguTheme),

                  if (event.waitlistIds.isNotEmpty) ...[
                    const SizedBox(height: 12),
                     _buildInfoCard(
                      context,
                      Icons.hourglass_empty_rounded,
                      '候補名單',
                      '${event.waitlistIds.length} 人正在排隊',
                      Colors.orange,
                    ),
                  ],

                  if (event.registrationDeadline != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      Icons.timer_outlined,
                      '報名截止',
                      DateFormat('MM/dd HH:mm').format(event.registrationDeadline!),
                      Colors.red,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  if (event.status == EventStatus.confirmed || event.status == EventStatus.completed)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Chat navigation
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
                              // Navigation
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
                  ),
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
          child: _buildActionButton(context, event, userId),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, EventStatus status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case EventStatus.pending:
        color = Colors.orange;
        text = '等待配對';
        icon = Icons.access_time_rounded;
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        text = '已確認';
        icon = Icons.check_circle_rounded;
        break;
      case EventStatus.completed:
        color = Colors.blue;
        text = '已完成';
        icon = Icons.task_alt_rounded;
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        text = '已取消';
        icon = Icons.cancel_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
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
  
  Widget _buildParticipantsCard(BuildContext context, DinnerEventModel event, ThemeData theme, ChinguTheme? chinguTheme) {
    final confirmedCount = event.participantIds.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (chinguTheme?.warning ?? Colors.orange).withOpacity(0.1),
            (chinguTheme?.warning ?? Colors.orange).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (chinguTheme?.warning ?? Colors.orange).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (chinguTheme?.warning ?? Colors.orange).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_rounded, size: 22, color: chinguTheme?.warning ?? Colors.orange),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '參加人數',
                  style: TextStyle(
                    fontSize: 13,
                    color: chinguTheme?.warning ?? Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '6 人（固定）\n目前已報名：$confirmedCount 人',
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

  Widget _buildActionButton(BuildContext context, DinnerEventModel event, String userId) {
    final isParticipant = event.participantIds.contains(userId);
    final isWaitlisted = event.waitlistIds.contains(userId);
    final isFull = event.participantIds.length >= 6;
    final isDeadlinePassed = event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!);
    final isCancelled = event.status == EventStatus.cancelled;
    final isCompleted = event.status == EventStatus.completed;

    if (isCompleted || isCancelled) {
      return GradientButton(
        text: isCompleted ? '活動已結束' : '活動已取消',
        onPressed: () {},
        isEnabled: false,
      );
    }

    if (isParticipant) {
      return GradientButton(
        text: '取消報名',
        onPressed: () => _showCancelDialog(context, event.id, userId, false),
        colors: [Colors.red.shade400, Colors.red.shade700],
      );
    }

    if (isWaitlisted) {
      return GradientButton(
        text: '取消候補',
        onPressed: () => _showCancelDialog(context, event.id, userId, true),
        colors: [Colors.orange.shade400, Colors.orange.shade700],
      );
    }

    if (isDeadlinePassed) {
       return GradientButton(
        text: '報名已截止',
        onPressed: () {},
        isEnabled: false,
      );
    }

    if (isFull) {
       return GradientButton(
        text: '加入候補',
        onPressed: () => _showJoinDialog(context, event.id, userId, true),
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _showJoinDialog(context, event.id, userId, false),
    );
  }

  void _showJoinDialog(BuildContext context, String eventId, String userId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入候補名單' : '確認報名'),
        content: Text(isWaitlist
            ? '活動名額已滿。您確定要加入候補名單嗎？如果有空位，您將自動遞補。'
            : '您確定要報名參加此活動嗎？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<DinnerEventProvider>().joinEvent(eventId, userId);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功')),
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
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String eventId, String userId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '取消候補' : '取消報名'),
        content: Text(isWaitlist
            ? '您確定要退出候補名單嗎？'
            : '您確定要取消報名嗎？如果在活動開始前24小時內取消，可能會被扣除信用點數。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
               try {
                await context.read<DinnerEventProvider>().leaveEvent(eventId, userId);
                if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已退出候補' : '已取消報名')),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }
}
