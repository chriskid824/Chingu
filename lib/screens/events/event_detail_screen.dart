import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/core/routes/app_router.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final eventId = ModalRoute.of(context)?.settings.arguments as String?;

    if (eventId == null) {
      return const Scaffold(body: Center(child: Text('無效的活動 ID')));
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: StreamBuilder<DinnerEventModel?>(
        stream: _eventService.getEventStream(eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('發生錯誤: ${snapshot.error}'));
          }

          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text('找不到活動'));
          }

          final isParticipant = event.participantIds.contains(_currentUserId);
          final isWaitlisted = event.waitlistIds.contains(_currentUserId);
          final isFull = event.isFull;
          final isDeadlinePassed = DateTime.now().isAfter(event.registrationDeadline);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  _buildAppBar(context, theme, event),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context, theme, chinguTheme, event),
                          const SizedBox(height: 24),

                          _buildInfoCard(
                            context,
                            Icons.calendar_today_rounded,
                            '日期時間',
                            '${DateFormat('yyyy年MM月dd日 (E)', 'zh_TW').format(event.dateTime)}\n${DateFormat('HH:mm').format(event.dateTime)}',
                            theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            Icons.timer_off_outlined,
                            '報名截止',
                            DateFormat('MM/dd HH:mm').format(event.registrationDeadline),
                            theme.colorScheme.error,
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
                            '${event.city} ${event.district}\n${event.restaurantName ?? '餐廳配對中...'}',
                            chinguTheme?.success ?? Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoCard(
                            context,
                            Icons.people_rounded,
                            '參加人數',
                            '6 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitlistIds.isNotEmpty ? '\n候補人數：${event.waitlistIds.length} 人' : ''}',
                            chinguTheme?.warning ?? Colors.orange,
                          ),

                          const SizedBox(height: 32),

                          if (isParticipant)
                            _buildActionButtons(context, theme, chinguTheme, event),

                          const SizedBox(height: 100), // Spacing for bottom bar
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(context, theme, event, isParticipant, isWaitlisted, isFull, isDeadlinePassed),
              ),
              if (_isLoading)
                Container(
                  color: Colors.black54,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme, DinnerEventModel event) {
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
          onPressed: () {
            // TODO: Implement share
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
                  Text(
                    event.statusText,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme, DinnerEventModel event) {
    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.confirmed:
        statusColor = chinguTheme?.success ?? Colors.green;
        statusText = '已確認';
        break;
      case EventStatus.completed:
        statusColor = Colors.grey;
        statusText = '已完成';
        break;
      case EventStatus.cancelled:
        statusColor = theme.colorScheme.error;
        statusText = '已取消';
        break;
      case EventStatus.pending:
      default:
        statusColor = theme.colorScheme.secondary;
        statusText = '等待配對';
        break;
    }

    return Row(
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
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
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

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme, DinnerEventModel event) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to chat
              // Navigator.of(context).pushNamed(AppRoutes.chatDetail, arguments: event.id);
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
                // TODO: Open maps
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
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    DinnerEventModel event,
    bool isParticipant,
    bool isWaitlisted,
    bool isFull,
    bool isDeadlinePassed,
  ) {
    String buttonText = '立即報名';
    VoidCallback? onPressed;
    bool isDestructive = false;

    if (isParticipant) {
      buttonText = '取消報名';
      isDestructive = true;
      onPressed = () => _showCancelConfirmation(context, event);
    } else if (isWaitlisted) {
      buttonText = '取消候補';
      isDestructive = true;
      onPressed = () => _showCancelWaitlistConfirmation(context, event);
    } else if (isDeadlinePassed) {
      buttonText = '已截止報名';
      onPressed = null;
    } else if (isFull) {
      buttonText = '加入候補清單';
      onPressed = () => _handleJoinWaitlist(context, event);
    } else {
      buttonText = '立即報名';
      onPressed = () => _handleJoin(context, event);
    }

    // Disable cancel if event is completed or cancelled
    if ((isParticipant || isWaitlisted) &&
        (event.status == EventStatus.completed || event.status == EventStatus.cancelled)) {
      // Allow viewing but not cancelling? Or maybe just hide button?
      // Actually if event is completed, you can't cancel.
      // If event is cancelled, you don't need to cancel.
      return const SizedBox.shrink();
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
        child: isDestructive
            ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : GradientButton(
                text: buttonText,
                onPressed: onPressed,
                // GradientButton might not support disabled state well,
                // wrap logic inside onPressed or modify GradientButton
                // Assuming if onPressed is null, it might not render disabled.
                // Let's assume GradientButton handles it or we wrap it.
              ),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context, DinnerEventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認報名'),
        content: const Text('確定要報名參加此活動嗎？\n報名後請準時出席。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認報名'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.joinEvent(event.id, _currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('報名成功！')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('報名失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinWaitlist(BuildContext context, DinnerEventModel event) async {
    setState(() => _isLoading = true);
    try {
      await _eventService.joinWaitlist(event.id, _currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已加入候補清單！如有空位將自動遞補。')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入候補失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCancelConfirmation(BuildContext context, DinnerEventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消報名'),
        content: const Text('確定要取消報名嗎？\n如果您頻繁取消，可能會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(event.id, _currentUserId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消報名')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showCancelWaitlistConfirmation(BuildContext context, DinnerEventModel event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消候補'),
        content: const Text('確定要取消候補嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(event.id, _currentUserId); // leaveEvent handles waitlist too
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已取消候補')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消失敗: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
