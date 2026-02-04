import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final AuthService _authService = AuthService();
  
  late Stream<DinnerEventModel?> _eventStream;

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _eventStream = _eventService.getEventStream(widget.eventId!);
    } else {
      _eventStream = Stream.value(null);
    }
  }

  void _handleRegistrationAction(DinnerEventModel event) async {
    final user = _authService.currentUser;
    if (user == null) {
      // Navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先登入')),
      );
      return;
    }

    final isRegistered = event.participantIds.contains(user.uid);
    final isWaitlisted = event.waitlist.contains(user.uid);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        event: event,
        currentUserId: user.uid,
        isRegistered: isRegistered,
        isWaitlisted: isWaitlisted,
        onConfirm: () {}, // Handled in async block below
      ),
    );

    if (confirmed == true) {
      try {
        if (isRegistered || isWaitlisted) {
          await _eventService.unregisterFromEvent(event.id, user.uid);
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已取消')),
            );
          }
        } else {
          final status = await _eventService.registerForEvent(event.id, user.uid);
          if (mounted) {
            String message = status.name == 'registered' ? '報名成功！' : '已加入候補名單';
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (widget.eventId == null) {
       return const Scaffold(body: Center(child: Text('未指定活動')));
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
           return const Scaffold(body: Center(child: Text('無法載入活動')));
        }

        final event = snapshot.data!;
        final user = _authService.currentUser;
        final isRegistered = user != null && event.participantIds.contains(user.uid);
        final isWaitlisted = user != null && event.waitlist.contains(user.uid);
        final isFull = event.isFull;

        String buttonText = '立即報名';
        Color? buttonColor;

        if (isRegistered) {
          buttonText = '取消報名';
          buttonColor = theme.colorScheme.error;
        } else if (isWaitlisted) {
          buttonText = '退出候補';
          buttonColor = theme.colorScheme.error;
        } else if (isFull) {
          buttonText = '加入候補名單';
          buttonColor = chinguTheme?.warning ?? Colors.orange;
        }

        // Format date and time
        final dateStr = "${event.dateTime.year}年${event.dateTime.month}月${event.dateTime.day}日";
        final timeStr = "${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}";

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
                              gradient: chinguTheme?.successGradient,
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
                        '$dateStr\n$timeStr',
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
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人\n候補人數：${event.waitlist.length} 人',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      const SizedBox(height: 32),

                      if (isRegistered) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {}, // TODO: Chat logic
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
                                  onPressed: () {}, // TODO: Navigation Logic
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
              child: SizedBox(
                height: 56, // GradientButton height default
                child: ElevatedButton(
                  onPressed: () => _handleRegistrationAction(event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor ?? theme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                   child: Text(
                     buttonText,
                     style: const TextStyle(
                       color: Colors.white,
                       fontSize: 16,
                       fontWeight: FontWeight.bold
                     )
                   ),
                ),
              ),
            ),
          ),
        );
      },
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
}
