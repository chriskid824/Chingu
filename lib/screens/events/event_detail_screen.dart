import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/enums/event_status.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _dinnerEventService = DinnerEventService();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _handleJoin() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認報名'),
        content: const Text('確定要參加這場晚餐聚會嗎？\n\n系統將會為您保留位置，請務必準時出席。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _dinnerEventService.joinEvent(widget.eventId, user.uid);
      if (mounted) _showSuccess('報名成功！');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消報名'),
        content: const Text('確定要取消報名嗎？\n\n注意：活動開始前 24 小時內取消可能會受到懲罰。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _dinnerEventService.leaveEvent(widget.eventId, user.uid);
      if (mounted) _showSuccess('已取消報名');
    } catch (e) {
      if (mounted) _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('請先登入')));
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _dinnerEventService.getEventStream(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text('發生錯誤: ${snapshot.error}')));
        }

        final event = snapshot.data;
        if (event == null) {
          return const Scaffold(body: Center(child: Text('找不到活動')));
        }

        final isParticipant = event.participantIds.contains(user.uid);
        final isWaitlisted = event.waitlistIds.contains(user.uid);
        final statusColor = _getStatusColor(event.status, chinguTheme, theme);

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
                              style: const TextStyle(fontSize: 40, color: Colors.white),
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
                              '${event.district}晚餐聚會',
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
                                  Icons.info_outline_rounded,
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
                        event.restaurantAddress ?? '${event.city}${event.district} (待定)',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '6 人滿團\n目前已報名：${event.participantIds.length} 人${event.waitlistIds.isNotEmpty ? '\n候補人數：${event.waitlistIds.length} 人' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      const SizedBox(height: 32),

                      if (isParticipant || isWaitlisted)
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {}, // TODO: Chat
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
              child: _buildActionButton(event, isParticipant, isWaitlisted, theme, chinguTheme),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    DinnerEventModel event,
    bool isParticipant,
    bool isWaitlisted,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isParticipant) {
      return OutlinedButton(
        onPressed: _handleLeave,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '取消報名',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: _handleLeave,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '取消候補',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
      );
    }

    if (event.status == EventStatus.closed || event.status == EventStatus.cancelled || event.status == EventStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.disabledColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          event.status.displayName,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.disabledColor,
          ),
        ),
      );
    }

    // Join or Waitlist
    final isFull = event.status == EventStatus.full || event.participantIds.length >= 6;

    return GradientButton(
      text: isFull ? '加入候補名單' : '立即報名',
      onPressed: _handleJoin,
      gradient: isFull ? chinguTheme?.warningGradient : null,
    );
  }

  Color _getStatusColor(EventStatus status, ChinguTheme? chinguTheme, ThemeData theme) {
    switch (status) {
      case EventStatus.open:
        return chinguTheme?.success ?? Colors.green;
      case EventStatus.full:
        return chinguTheme?.warning ?? Colors.orange;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return theme.disabledColor;
      case EventStatus.closed:
        return theme.disabledColor;
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
