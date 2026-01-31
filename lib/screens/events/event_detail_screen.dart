import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
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

  Future<void> _handleJoin(String userId) async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認報名'),
        content: const Text('確定要報名參加此活動嗎？\n\n出席活動將獲得 10 點信用積分，爽約將扣除 20 點。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('確認報名'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.joinEvent(widget.eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('報名成功！'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLeave(String userId, bool isWaitlist) async {
    if (_isLoading) return;

    final title = isWaitlist ? '退出等候' : '取消報名';
    final content = isWaitlist
        ? '確定要退出等候名單嗎？'
        : '確定要取消報名嗎？\n\n活動開始前 24 小時內取消可能會扣除信用積分。';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('保留'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(title),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(widget.eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleWaitlist(String userId) async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('加入等候名單'),
        content: const Text('活動目前已額滿。確定要加入等候名單嗎？\n\n如果有空位釋出，系統將自動為您遞補並通知您。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('加入等候'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.addToWaitlist(widget.eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入等候名單'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('找不到活動')),
          );
        }

        final theme = Theme.of(context);
        final chinguTheme = theme.extension<ChinguTheme>();
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUserId = authProvider.currentUser?.uid;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, event, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, event, chinguTheme, theme),
                      const SizedBox(height: 24),
                      _buildInfoCards(context, event, chinguTheme, theme),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, event, chinguTheme, theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, currentUserId, chinguTheme, theme),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, DinnerEventModel event, ThemeData theme) {
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
          onPressed: () {},
        ),
        const SizedBox(width: 8),
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
    );
  }

  Widget _buildHeader(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme, ThemeData theme) {
    return Row(
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
            color: event.status.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: event.status.color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(event.status),
                size: 16,
                color: event.status.color,
              ),
              const SizedBox(width: 4),
              Text(
                event.statusText,
                style: TextStyle(
                  fontSize: 13,
                  color: event.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(EventStatus status) {
    switch (status) {
      case EventStatus.pending: return Icons.access_time_rounded;
      case EventStatus.confirmed: return Icons.check_circle_rounded;
      case EventStatus.full: return Icons.group_off_rounded;
      case EventStatus.completed: return Icons.flag_rounded;
      case EventStatus.cancelled: return Icons.cancel_rounded;
    }
  }

  Widget _buildInfoCards(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme, ThemeData theme) {
    return Column(
      children: [
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
          '${event.city}${event.district}${event.restaurantName != null ? '\n${event.restaurantName}' : ''}',
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitlist.isNotEmpty ? '\n等候人數：${event.waitlist.length} 人' : ''}',
          chinguTheme?.warning ?? Colors.orange,
        ),
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

  Widget _buildActionButtons(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme, ThemeData theme) {
    // Only show these if confirmed/joined
    return Row(
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
    );
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, String? currentUserId, ChinguTheme? chinguTheme, ThemeData theme) {
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    String buttonText;
    VoidCallback? onPressed;
    Color buttonColor;
    bool isOutlined = false;

    bool isJoined = event.participantIds.contains(currentUserId);
    bool isWaitlisted = event.waitlist.contains(currentUserId);
    bool isFull = event.isFull;
    bool isDeadlinePassed = event.registrationDeadline != null && DateTime.now().isAfter(event.registrationDeadline!);
    bool isCompleted = event.status == EventStatus.completed || event.status == EventStatus.cancelled;

    if (isCompleted) {
        buttonText = '活動已結束';
        buttonColor = Colors.grey;
        onPressed = null;
    } else if (isJoined) {
        buttonText = '取消報名';
        buttonColor = Colors.red;
        isOutlined = true;
        onPressed = () => _handleLeave(currentUserId, false);
    } else if (isWaitlisted) {
        buttonText = '退出等候名單';
        buttonColor = Colors.orange;
        isOutlined = true;
        onPressed = () => _handleLeave(currentUserId, true);
    } else if (isDeadlinePassed) {
        buttonText = '報名已截止';
        buttonColor = Colors.grey;
        onPressed = null;
    } else if (isFull) {
        buttonText = '加入等候名單';
        buttonColor = Colors.orange;
        onPressed = () => _handleWaitlist(currentUserId);
    } else {
        buttonText = '立即報名';
        buttonColor = theme.colorScheme.primary; // Or gradient
        onPressed = () => _handleJoin(currentUserId);
    }

    // Special handling for loading state
    if (_isLoading) {
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
        child: const SafeArea(
          child: Center(child: CircularProgressIndicator(), heightFactor: 1),
        ),
      );
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
        child: onPressed == null
            ? FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.grey,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              )
            : isOutlined
                ? OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: buttonColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(buttonText,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: buttonColor)),
                  )
                : GradientButton(
                    text: buttonText,
                    onPressed: onPressed!,
                    gradient: buttonColor == Colors.orange
                        ? const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange])
                        : null,
                  ),
      ),
    );
  }
}
