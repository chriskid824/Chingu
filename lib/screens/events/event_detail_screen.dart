import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  DinnerEventModel? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DinnerEventModel) {
      setState(() {
        _event = args;
        _isLoading = false;
      });
    } else if (args is String) {
      // Load by ID
      try {
        final event = await _eventService.getEvent(args);
        setState(() {
          _event = event;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = '無效的活動資料';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegistration(String userId) async {
    if (_event == null) return;

    final isRegistered = _event!.participantIds.contains(userId);
    final isWaitlisted = _event!.waitingList.contains(userId);
    final isFull = _event!.isFull;

    EventActionType action;
    if (isRegistered || isWaitlisted) {
       action = isRegistered ? EventActionType.cancel : EventActionType.leaveWaitlist;
    } else {
       action = isFull ? EventActionType.joinWaitlist : EventActionType.join;
    }

    final confirmed = await EventRegistrationDialog.show(
      context,
      actionType: action,
      eventTitle: '${_event!.city} 晚餐聚會',
      waitlistPosition: isWaitlisted
          ? '${_event!.waitingList.indexOf(userId) + 1}'
          : null,
    );

    if (confirmed == true && mounted) {
      try {
        if (action == EventActionType.cancel || action == EventActionType.leaveWaitlist) {
          await _eventService.leaveEvent(_event!.id, userId);
        } else {
          await _eventService.joinEvent(_event!.id, userId);
        }

        // Reload event data
        final updatedEvent = await _eventService.getEvent(_event!.id);
        if (updatedEvent != null) {
          setState(() {
            _event = updatedEvent;
          });
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(
               action == EventActionType.cancel || action == EventActionType.leaveWaitlist
               ? '已取消'
               : (action == EventActionType.join ? '報名成功' : '已加入候補')
             )),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    if (_error != null || _event == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: Center(child: Text(_error ?? '找不到活動')),
      );
    }

    final event = _event!;
    final isRegistered = userId != null && event.participantIds.contains(userId);
    final isWaitlisted = userId != null && event.waitingList.contains(userId);
    final statusColor = _getStatusColor(event.eventStatus, chinguTheme, theme);

    // Format Date
    final dateFormat = DateFormat('yyyy年MM月dd日 (E) HH:mm', 'zh_TW');
    final dateStr = dateFormat.format(event.dateTime);

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
                          border: Border.all(color: statusColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(event.eventStatus),
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
                  ),
                  const SizedBox(height: 24),
                  
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
                    '${event.city} ${event.district}\n${event.restaurantName ?? "餐廳確認中..."}',
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
                  if (event.notes != null) ...[
                     const SizedBox(height: 12),
                     _buildInfoCard(
                        context,
                        Icons.sticky_note_2_rounded,
                        '備註',
                        event.notes!,
                        theme.colorScheme.tertiary,
                      ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  if (isRegistered) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Navigate to Chat
                              // Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: ...);
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
                                  '群組聊天',
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
                        // Add Navigation button logic here if location is available
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
          child: _buildActionButton(context, event, userId, isRegistered, isWaitlisted, chinguTheme, theme),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    DinnerEventModel event,
    String? userId,
    bool isRegistered,
    bool isWaitlisted,
    ChinguTheme? chinguTheme,
    ThemeData theme,
  ) {
    if (userId == null) {
       return const SizedBox.shrink(); // Or login button
    }

    if (event.isRegistrationClosed && !isRegistered && !isWaitlisted) {
       return ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
             padding: const EdgeInsets.symmetric(vertical: 16),
             backgroundColor: theme.disabledColor,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('報名已截止', style: TextStyle(color: Colors.white)),
       );
    }

    if (isRegistered) {
      return OutlinedButton(
        onPressed: () => _handleRegistration(userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('取消報名', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: () => _handleRegistration(userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text('退出候補 (順位: ${event.waitingList.indexOf(userId) + 1})', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
      );
    }

    if (event.isFull) {
      return GradientButton(
        text: '加入候補名單',
        gradient: chinguTheme?.secondaryGradient,
        onPressed: () => _handleRegistration(userId),
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _handleRegistration(userId),
    );
  }

  Color _getStatusColor(EventStatus status, ChinguTheme? chinguTheme, ThemeData theme) {
    switch (status) {
      case EventStatus.pending:
        return chinguTheme?.warning ?? Colors.orange;
      case EventStatus.confirmed:
        return chinguTheme?.success ?? Colors.green;
      case EventStatus.completed:
        return theme.colorScheme.primary;
      case EventStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.pending:
        return Icons.hourglass_empty_rounded;
      case EventStatus.confirmed:
        return Icons.check_circle_rounded;
      case EventStatus.completed:
        return Icons.task_alt_rounded;
      case EventStatus.cancelled:
        return Icons.cancel_rounded;
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
