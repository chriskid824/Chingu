import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final eventId = ModalRoute.of(context)?.settings.arguments as String?;
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('活動 ID 遺失')),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
           return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('無法載入活動詳情')),
          );
        }

        final event = snapshot.data!;
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
                      // Placeholder or Restaurant Image if available
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
                        '${event.city} ${event.district}',
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
                       if (event.waitlist.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          Icons.hourglass_empty_rounded,
                          '候補人數',
                          '${event.waitlist.length} 人正在候補',
                          Colors.purple,
                        ),
                      ],
                      const SizedBox(height: 32),

                      if (event.status != EventStatus.cancelled) ...[
                        _buildActionButtons(context, event, theme, chinguTheme),
                      ] else
                        Center(child: Text('活動已取消', style: TextStyle(color: Colors.red, fontSize: 18))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, theme),
        );
      }
    );
  }

  Widget _buildStatusBadge(BuildContext context, EventStatus status) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color color;
    IconData icon;

    switch (status) {
      case EventStatus.pending:
        color = Colors.orange;
        icon = Icons.access_time_filled;
        break;
      case EventStatus.confirmed:
        color = chinguTheme?.success ?? Colors.green;
        icon = Icons.check_circle;
        break;
      case EventStatus.completed:
        color = Colors.blue;
        icon = Icons.task_alt;
        break;
      case EventStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
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

  // Only show navigation/chat if joined
  Widget _buildActionButtons(BuildContext context, DinnerEventModel event, ThemeData theme, ChinguTheme? chinguTheme) {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final isJoined = event.participantIds.contains(userId);

    if (!isJoined) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Navigate to Chat
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
                // Navigate to Map/Navigation
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
    if (event.status == EventStatus.cancelled || event.status == EventStatus.completed) {
      return const SizedBox.shrink();
    }

    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final isJoined = event.participantIds.contains(userId);
    final isWaitlisted = event.waitlist.contains(userId);
    final isFull = event.isFull;
    final isClosed = event.isRegistrationClosed;

    String buttonText = '立即報名';
    VoidCallback? onPressed;
    Color? buttonColor;

    if (isJoined) {
      buttonText = '取消報名';
      buttonColor = Colors.redAccent;
      onPressed = () => _showCancelDialog(context, event.id);
    } else if (isWaitlisted) {
      buttonText = '取消候補';
      buttonColor = Colors.orange;
      onPressed = () => _showCancelDialog(context, event.id);
    } else if (isClosed) {
      buttonText = '報名已截止';
      onPressed = null; // Disable button
    } else if (isFull) {
      buttonText = '加入候補';
      onPressed = () => _handleJoinWaitlist(context, event.id);
    } else {
      buttonText = '立即報名';
      onPressed = () => _handleJoin(context, event.id);
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
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
               backgroundColor: buttonColor ?? theme.colorScheme.primary,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               elevation: 0,
            ),
            child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context, String eventId) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.joinEvent(eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報名成功！')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('報名失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleJoinWaitlist(BuildContext context, String eventId) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.joinWaitlist(eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入候補名單')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加入候補失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCancelDialog(BuildContext context, String eventId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消確認'),
        content: const Text('確定要取消嗎？如果您在活動開始前爽約，可能會扣除信用分數。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCancel(context, eventId);
            },
            child: const Text('確定取消', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, String eventId) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _eventService.leaveEvent(eventId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('取消失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
