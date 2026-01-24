import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final eventId = ModalRoute.of(context)?.settings.arguments as String?;

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('錯誤')),
        body: const Center(child: Text('無效的活動 ID')),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('找不到活動')),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, event, chinguTheme),
                      const SizedBox(height: 24),
                      _buildEventDetails(context, event, theme, chinguTheme),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, theme, chinguTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, theme),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DinnerEventModel event, ChinguTheme? chinguTheme) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            '${event.participantIds.length}人晚餐聚會',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor(event.status, chinguTheme).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getStatusColor(event.status, chinguTheme)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(event.status),
                size: 16,
                color: _getStatusColor(event.status, chinguTheme),
              ),
              const SizedBox(width: 4),
              Text(
                event.statusText,
                style: TextStyle(
                  fontSize: 13,
                  color: _getStatusColor(event.status, chinguTheme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetails(BuildContext context, DinnerEventModel event, ThemeData theme, ChinguTheme? chinguTheme) {
    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');

    return Column(
      children: [
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
          '${event.budgetRangeText} / 人',
          theme.colorScheme.secondary,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.location_on_rounded,
          '地點',
          '${event.city} ${event.district}\n(詳細餐廳將於成團後公佈)',
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '${event.participantIds.length} / 6 人\n候補人數: ${event.waitlistIds.length} 人',
          chinguTheme?.warning ?? Colors.orange,
        ),
        if (event.registrationDeadline != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.access_time_filled_rounded,
            '報名截止',
            dateFormat.format(event.registrationDeadline!),
            Colors.redAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Chat logic
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
                // TODO: Navigation logic
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

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.uid;

    if (userId == null) return const SizedBox.shrink();

    final status = event.getUserRegistrationStatus(userId);
    final isFull = event.isFull;

    String buttonText;
    RegistrationAction action;
    Color? buttonColor;

    switch (status) {
      case EventRegistrationStatus.registered:
        buttonText = '取消報名';
        action = RegistrationAction.leave;
        buttonColor = Colors.redAccent;
        break;
      case EventRegistrationStatus.waitlisted:
        buttonText = '退出候補';
        action = RegistrationAction.leaveWaitlist;
        buttonColor = Colors.redAccent;
        break;
      case EventRegistrationStatus.none:
      default:
        if (isFull) {
          buttonText = '加入候補 (${event.waitlistIds.length + 1})';
          action = RegistrationAction.joinWaitlist;
          buttonColor = Colors.orange;
        } else {
          buttonText = '立即報名';
          action = RegistrationAction.join;
          buttonColor = null; // Use default gradient
        }
        break;
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
        child: GradientButton(
          text: buttonText,
          gradient: buttonColor != null ? LinearGradient(colors: [buttonColor, buttonColor]) : null,
          onPressed: () => _showRegistrationDialog(context, event.id, userId, action),
        ),
      ),
    );
  }

  void _showRegistrationDialog(
    BuildContext context,
    String eventId,
    String userId,
    RegistrationAction action
  ) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (context) => EventRegistrationDialog(
        action: action,
        isProcessing: _isProcessing,
        onConfirm: () async {
          setState(() {
            _isProcessing = true;
          });
          // Close dialog first to avoid context issues or update dialog state?
          // Dialog takes isProcessing, but to update it, we need to rebuild the dialog.
          // Simplest is to close dialog and show loading, or use StatefulBuilder inside dialog.
          // The current Dialog is Stateless.

          // Better approach: Close dialog, show loading overlay or just execute and handle error.
          Navigator.of(context).pop();

          _handleRegistrationAction(eventId, userId, action);
        },
      ),
    );
  }

  Future<void> _handleRegistrationAction(String eventId, String userId, RegistrationAction action) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (action == RegistrationAction.join || action == RegistrationAction.joinWaitlist) {
        await _eventService.registerForEvent(eventId, userId);
      } else {
        await _eventService.unregisterFromEvent(eventId, userId);
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_getSuccessMessage(action))),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  String _getSuccessMessage(RegistrationAction action) {
    switch (action) {
      case RegistrationAction.join:
        return '報名成功！';
      case RegistrationAction.joinWaitlist:
        return '已加入候補名單';
      case RegistrationAction.leave:
        return '已取消報名';
      case RegistrationAction.leaveWaitlist:
        return '已退出候補名單';
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

  Color _getStatusColor(EventStatus status, ChinguTheme? chinguTheme) {
    switch (status) {
      case EventStatus.pending:
        return Colors.blue;
      case EventStatus.confirmed:
        return chinguTheme?.success ?? Colors.green;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.cancelled:
        return Colors.red;
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
}
