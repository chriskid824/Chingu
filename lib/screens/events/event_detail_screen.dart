import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

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
  late final DinnerEventService _dinnerEventService;
  late final Stream<DinnerEventModel?> _eventStream;

  @override
  void initState() {
    super.initState();
    _dinnerEventService = DinnerEventService();
    _eventStream = _dinnerEventService.getEventStream(widget.eventId);
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.firebaseUser?.uid;

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('活動詳情')),
            body: const Center(child: Text('找不到活動')),
          );
        }

        final event = snapshot.data!;
        final isParticipant = userId != null && event.participantIds.contains(userId);
        final isWaitlisted = userId != null && event.waitingListIds.contains(userId);
        final isFull = event.isFull;
        final isClosed = event.status == EventStatus.closed ||
            event.status == EventStatus.cancelled ||
            event.status == EventStatus.completed;

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
                              Colors.black.withValues(alpha: 0.3),
                              Colors.black.withValues(alpha: 0.6),
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
                              '${event.city}${event.district} 6人晚餐',
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
                        event.budgetRangeText,
                        theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.location_on_rounded,
                        '地點',
                        event.restaurantName ?? '${event.city}${event.district} (待定)',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '6 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitingListIds.isNotEmpty ? '\n等候中：${event.waitingListIds.length} 人' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),
                      if (event.registrationDeadline != null) ...[
                        const SizedBox(height: 12),
                         _buildInfoCard(
                          context,
                          Icons.timer_rounded,
                          '報名截止',
                          DateFormat('yyyy/MM/dd HH:mm').format(event.registrationDeadline!),
                          Colors.redAccent,
                        ),
                      ],

                      if (isParticipant) ...[
                        const SizedBox(height: 32),
                        Row(
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
                  color: theme.shadowColor.withValues(alpha: 0.05),
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
                isClosed,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(BuildContext context, EventStatus status) {
    Color color;
    String text;

    switch (status) {
      case EventStatus.pending:
        color = Colors.orange;
        text = '等待配對';
        break;
      case EventStatus.confirmed:
        color = Colors.green;
        text = '已確認';
        break;
      case EventStatus.completed:
        color = Colors.blue;
        text = '已完成';
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        text = '已取消';
        break;
      case EventStatus.full:
        color = Colors.purple;
        text = '已滿員';
        break;
      case EventStatus.closed:
        color = Colors.grey;
        text = '報名截止';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
    String? userId,
    bool isParticipant,
    bool isWaitlisted,
    bool isFull,
    bool isClosed,
  ) {
    if (userId == null) {
      return GradientButton(
        text: '請先登入',
        onPressed: () {}, // Should navigate to login
        isEnabled: false,
      );
    }

    if (isClosed) {
      return GradientButton(
        text: '報名已截止',
        onPressed: () {},
        isEnabled: false,
      );
    }

    if (isParticipant) {
      return OutlinedButton(
        onPressed: () => _showCancelDialog(context, event, userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          '取消報名',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }

    if (isWaitlisted) {
       return OutlinedButton(
        onPressed: () => _showCancelDialog(context, event, userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          '取消排隊',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      );
    }

    if (isFull) {
      return GradientButton(
        text: '加入等候清單',
        onPressed: () => _showJoinDialog(context, event, userId, isWaitlist: true),
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _showJoinDialog(context, event, userId, isWaitlist: false),
    );
  }

  void _showJoinDialog(BuildContext context, DinnerEventModel event, String userId, {required bool isWaitlist}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入等候清單' : '確認報名'),
        content: Text(isWaitlist
            ? '目前活動已額滿，您確定要加入等候清單嗎？若有人取消，您將自動遞補。'
            : '您確定要報名此活動嗎？'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('再考慮'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dinnerEventService.joinEvent(event.id, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已加入等候清單' : '報名成功！')),
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

  void _showCancelDialog(BuildContext context, DinnerEventModel event, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消報名'),
        content: Text('您確定要取消報名嗎？${event.dateTime.difference(DateTime.now()).inHours < 24 ? '\n\n注意：活動開始前 24 小時內取消可能會扣除信用分數。' : ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _dinnerEventService.cancelRegistration(event.id, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消報名')),
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
            child: const Text('確定取消', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
