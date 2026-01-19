import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  DinnerEventModel? _initialEvent;
  bool _isLoadingAction = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DinnerEventModel) {
      _initialEvent = args;
    }
  }

  Future<void> _handleRegistrationAction(DinnerEventModel event) async {
    if (_userId == null) return;

    // Determine current status
    final currentStatus = event.getUserRegistrationStatus(_userId!);
    final isFull = event.isFull;
    final waitlistCount = event.waitingListIds.length;

    // Show Dialog
    final confirmed = await EventRegistrationDialog.show(
      context,
      currentStatus: currentStatus,
      isFull: isFull,
      waitlistCount: waitlistCount,
      eventDate: event.dateTime,
    );

    if (confirmed == true) {
      setState(() => _isLoadingAction = true);
      try {
        if (currentStatus == EventRegistrationStatus.none) {
          // Register or Join Waitlist
          await _eventService.registerForEvent(event.id, _userId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('報名成功！')),
            );
          }
        } else {
          // Cancel
          await _eventService.unregisterFromEvent(event.id, _userId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已取消報名')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失敗: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingAction = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_initialEvent == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到活動資訊')),
      );
    }

    // Use StreamBuilder for real-time updates
    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(_initialEvent!.id),
      initialData: _initialEvent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
        }

        final event = snapshot.data;
        if (event == null) {
           return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final chinguTheme = theme.extension<ChinguTheme>();
        final dateStr = DateFormat('yyyy年MM月dd日 (E)').format(event.dateTime);
        final timeStr = DateFormat('HH:mm').format(event.dateTime);

        final userStatus = _userId != null
            ? event.getUserRegistrationStatus(_userId!)
            : EventRegistrationStatus.none;

        String actionButtonText;
        bool isActionEnabled = true;

        if (userStatus == EventRegistrationStatus.registered) {
           actionButtonText = '取消報名';
        } else if (userStatus == EventRegistrationStatus.waitlist) {
           actionButtonText = '退出候補';
        } else {
           if (event.isFull) {
             actionButtonText = '加入候補';
           } else {
             actionButtonText = '立即報名';
           }
        }

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
                        errorBuilder: (_,__,___) => Container(color: Colors.grey),
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
                        '${event.city}${event.district}',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.currentParticipants} 人',
                        chinguTheme?.warning ?? Colors.orange,
                        trailing: event.waitingListIds.isNotEmpty
                            ? Text(
                                '候補: ${event.waitingListIds.length}人',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                              )
                            : null,
                      ),

                      const SizedBox(height: 32),

                      // Only show actions if registered
                      if (userStatus == EventRegistrationStatus.registered) ...[
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: chinguTheme?.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: () {},
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
              child: GradientButton(
                text: actionButtonText,
                isLoading: _isLoadingAction,
                onPressed: isActionEnabled
                    ? () => _handleRegistrationAction(event)
                    : () {},
                gradient: (userStatus == EventRegistrationStatus.registered ||
                          userStatus == EventRegistrationStatus.waitlist)
                    ? LinearGradient(colors: [theme.disabledColor, theme.disabledColor])
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
    {Widget? trailing}
  ) {
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
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
