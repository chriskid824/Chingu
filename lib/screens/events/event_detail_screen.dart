import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});
  
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  String? _eventId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _eventId = args?['eventId'];
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId == null) {
      return const Scaffold(body: Center(child: Text('Error: No event ID')));
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(_eventId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('無法加載活動詳情')),
          );
        }

        final event = snapshot.data!;
        return _buildContent(context, event);
      },
    );
  }

  Widget _buildContent(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final userId = context.read<AuthProvider>().uid;

    final isParticipant = event.participantIds.contains(userId);
    final isWaitlisted = event.waitingListIds.contains(userId);
    final isFull = event.participantIds.length >= event.maxParticipants;
    final isPastDeadline = event.isPastDeadline;

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
                          '${event.maxParticipants}人晚餐聚會',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _getStatusGradient(event.status, chinguTheme),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.statusText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                    '${event.city} ${event.district}\n${event.restaurantAddress ?? "地點將於確認後公佈"}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  if (event.waitingListIds.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.only(top: 12),
                       child: _buildInfoCard(
                        context,
                        Icons.hourglass_empty_rounded,
                        '候補人數',
                        '${event.waitingListIds.length} 人在等待',
                        Colors.purple,
                                           ),
                     ),
                  
                  const SizedBox(height: 32),
                  
                  if (isParticipant)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Chat navigation
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
                                // TODO: Navigation
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
          child: _buildActionButton(context, event, isParticipant, isWaitlisted, isFull, isPastDeadline),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    DinnerEventModel event,
    bool isParticipant,
    bool isWaitlisted,
    bool isFull,
    bool isPastDeadline
  ) {
    if (event.status == EventStatus.cancelled || event.status == EventStatus.completed) {
      return GradientButton(
        text: event.statusText,
        onPressed: null, // Disabled
        colors: const [Colors.grey, Colors.grey],
      );
    }

    if (isParticipant) {
      return OutlinedButton(
        onPressed: () => _showCancelDialog(context, event.id, false),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('取消報名', style: TextStyle(color: Colors.red, fontSize: 16)),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: () => _showCancelDialog(context, event.id, true),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('取消候補', style: TextStyle(color: Colors.orange, fontSize: 16)),
      );
    }

    if (isPastDeadline) {
       return const GradientButton(
        text: '報名截止',
        onPressed: null,
        colors: [Colors.grey, Colors.grey],
      );
    }

    if (isFull) {
       return GradientButton(
        text: '加入候補名單',
        onPressed: () => _handleJoinWaitlist(context, event.id),
        colors: const [Colors.orange, Colors.deepOrange],
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _handleJoin(context, event.id),
    );
  }

  LinearGradient? _getStatusGradient(EventStatus status, ChinguTheme? chinguTheme) {
    switch (status) {
      case EventStatus.pending:
        return chinguTheme?.warningGradient;
      case EventStatus.confirmed:
        return chinguTheme?.successGradient;
      case EventStatus.completed:
        return chinguTheme?.primaryGradient;
      case EventStatus.cancelled:
        return const LinearGradient(colors: [Colors.grey, Colors.black45]);
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

  void _handleJoin(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認報名'),
        content: const Text('您確定要報名此晚餐活動嗎？\n報名後若無故缺席將會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              _performAction(context, () async {
                 final userId = context.read<AuthProvider>().uid!;
                 await _eventService.joinEvent(eventId, userId);
              }, '報名成功');
            },
            child: const Text('確認報名'),
          ),
        ],
      ),
    );
  }

  void _handleJoinWaitlist(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入候補'),
        content: const Text('目前名額已滿，確定要加入候補名單嗎？\n若有空缺將會自動遞補並通知您。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
               _performAction(context, () async {
                 final userId = context.read<AuthProvider>().uid!;
                 await _eventService.joinWaitlist(eventId, userId);
              }, '已加入候補名單');
            },
            child: const Text('加入候補'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String eventId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '取消候補' : '取消報名'),
        content: Text(isWaitlist ? '確定要取消候補嗎？' : '確定要取消報名嗎？\n頻繁取消可能會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
               _performAction(context, () async {
                 final userId = context.read<AuthProvider>().uid!;
                 await _eventService.leaveEvent(eventId, userId);
              }, isWaitlist ? '已取消候補' : '已取消報名');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(BuildContext context, Future<void> Function() action, String successMessage) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await action();

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
