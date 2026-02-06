import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/models/event_registration_status.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _handleRegistration(BuildContext context, DinnerEventModel event, bool isCancelling) async {
    // Show confirmation dialog
    final confirmed = await EventRegistrationDialog.show(
      context,
      event: event,
      isCancelling: isCancelling
    );

    if (confirmed == true && mounted) {
      try {
        if (isCancelling) {
          await _eventService.unregisterFromEvent(event.id, _currentUserId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消報名')),
          );
        } else {
          await _eventService.registerForEvent(event.id, _currentUserId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(event.isFull ? '已加入候補名單' : '報名成功！')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy年MM月dd日 (E) HH:mm', 'zh_TW');

    final eventArg = ModalRoute.of(context)?.settings.arguments as DinnerEventModel?;

    if (eventArg == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('活動詳情')),
        body: const Center(child: Text('找不到活動資料')),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(eventArg.id),
      initialData: eventArg,
      builder: (context, snapshot) {
        final event = snapshot.data;
        if (event == null) {
           return Scaffold(
             appBar: AppBar(),
             body: const Center(child: Text('活動已不存在')),
           );
        }

        final isRegistered = event.isUserConfirmed(_currentUserId);
        final isWaitlisted = event.isUserWaitlisted(_currentUserId);
        final isFull = event.isFull;

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
                      // Placeholder image or map snapshot could go here
                      Container(color: theme.colorScheme.primaryContainer),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.1),
                              Colors.black.withOpacity(0.4),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 80,
                              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
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
                          _buildStatusTag(context, event, chinguTheme),
                        ],
                      ),
                      const SizedBox(height: 24),

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
                        event.budgetRangeText,
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
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.confirmedCount} 人${event.waitlist.isNotEmpty ? '\n候補人數：${event.waitlist.length} 人' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (event.notes != null && event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('備註', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(event.notes!, style: theme.textTheme.bodyMedium),
                      ],

                      // Actions like Chat (only if registered)
                      if (isRegistered) ...[
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to chat
                              // Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: ...);
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('進入活動群組'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
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
              child: isRegistered || isWaitlisted
                ? OutlinedButton(
                    onPressed: () => _handleRegistration(context, event, true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isWaitlisted ? '取消候補' : '取消報名'),
                  )
                : GradientButton(
                    text: isFull ? '加入候補名單' : '立即報名',
                    onPressed: () => _handleRegistration(context, event, false),
                    // If isFull, maybe different color? GradientButton might support style
                  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTag(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme) {
    String text = event.statusText;
    Color color = Colors.grey;
    IconData icon = Icons.info;

    if (event.status == 'confirmed') {
      color = chinguTheme?.success ?? Colors.green;
      icon = Icons.check_circle;
    } else if (event.status == 'pending') {
      color = Colors.blue;
      icon = Icons.hourglass_empty;
    } else if (event.status == 'cancelled') {
      color = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
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
