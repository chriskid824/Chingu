import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_status.dart';
import 'package:chingu/services/auth_service.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _dinnerEventService = DinnerEventService();
  final _authService = AuthService();
  late String _eventId;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _eventId = args;
      } else {
        _eventId = '';
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_eventId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('無效的活動 ID')),
      );
    }

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return StreamBuilder<DinnerEventModel?>(
      stream: _dinnerEventService.getEventStream(_eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!;
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, theme, event),
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
                          _buildStatusBadge(theme, chinguTheme, event),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, theme, chinguTheme, event),
                      const SizedBox(height: 32),
                      _buildActionButtons(theme, chinguTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(theme, event),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, ThemeData theme, DinnerEventModel event) {
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

  Widget _buildStatusBadge(ThemeData theme, ChinguTheme? chinguTheme, DinnerEventModel event) {
    Color badgeColor;
    IconData icon;
    String text = event.statusText;

    switch (event.status) {
      case EventStatus.confirmed:
        badgeColor = chinguTheme?.success ?? Colors.green;
        icon = Icons.check_circle;
        break;
      case EventStatus.completed:
        badgeColor = theme.colorScheme.primary;
        icon = Icons.flag;
        break;
      case EventStatus.cancelled:
        badgeColor = theme.colorScheme.error;
        icon = Icons.cancel;
        break;
      default:
        badgeColor = chinguTheme?.warning ?? Colors.orange;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
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
            text,
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

  Widget _buildInfoSection(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme, DinnerEventModel event) {
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
          '${event.city} ${event.district}\n${event.restaurantAddress ?? "餐廳配對中..."}',
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '${event.participantIds.length} / 6 人\n候補: ${event.waitingList.length} 人',
          chinguTheme?.warning ?? Colors.orange,
        ),
        if (event.isRegistrationClosed) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.access_time_filled,
            '報名截止',
            '此活動報名已截止',
            theme.colorScheme.error,
          ),
        ]
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

  Widget _buildActionButtons(ThemeData theme, ChinguTheme? chinguTheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
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

  Widget _buildBottomBar(ThemeData theme, DinnerEventModel event) {
    final userId = _authService.currentUser?.uid;
    if (userId == null) return const SizedBox.shrink();

    final isJoined = event.isUserConfirmed(userId);
    final isWaitlisted = event.isUserWaitlisted(userId);
    final isFull = event.isFull;
    final isClosed = event.isRegistrationClosed;

    String buttonText = '立即報名';
    VoidCallback? onPressed;
    EventActionType actionType = EventActionType.join;
    LinearGradient? buttonGradient;

    if (isJoined) {
      if (isClosed) {
        buttonText = '活動即將開始';
        onPressed = null;
      } else {
        buttonText = '取消報名';
        actionType = EventActionType.cancel;
        buttonGradient = LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]);
        onPressed = () => _showConfirmationDialog(EventActionType.cancel, event.id, userId);
      }
    } else if (isWaitlisted) {
      buttonText = '退出候補';
      actionType = EventActionType.leaveWaitlist;
      buttonGradient = LinearGradient(colors: [Colors.red.shade400, Colors.red.shade700]);
      onPressed = () => _showConfirmationDialog(EventActionType.leaveWaitlist, event.id, userId);
    } else if (isClosed) {
      buttonText = '報名已截止';
      onPressed = null;
    } else if (isFull) {
      buttonText = '加入候補名單';
      actionType = EventActionType.joinWaitlist;
      // Orange gradient for waitlist? Default is fine or custom.
      onPressed = () => _showConfirmationDialog(EventActionType.joinWaitlist, event.id, userId);
    } else {
      buttonText = '立即報名';
      actionType = EventActionType.join;
      onPressed = () => _showConfirmationDialog(EventActionType.join, event.id, userId);
    }

    if (event.status == EventStatus.cancelled) {
        buttonText = '活動已取消';
        onPressed = null;
    } else if (event.status == EventStatus.completed) {
        buttonText = '活動已結束';
        onPressed = null;
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
          onPressed: onPressed,
          gradient: buttonGradient,
        ),
      ),
    );
  }

  void _showConfirmationDialog(EventActionType type, String eventId, String userId) {
    String title;
    String content;

    switch (type) {
      case EventActionType.join:
        title = '確認報名';
        content = '確定要參加這場晚餐聚會嗎？報名後若無故缺席將會扣除信用積分。';
        break;
      case EventActionType.cancel:
        title = '取消報名';
        content = '確定要取消報名嗎？如果在活動前 24 小時內取消，可能會受到懲罰。';
        break;
      case EventActionType.joinWaitlist:
        title = '加入候補';
        content = '目前活動已滿，確定要加入候補名單嗎？若有名額釋出將自動替補。';
        break;
      case EventActionType.leaveWaitlist:
        title = '退出候補';
        content = '確定要退出候補名單嗎？';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        type: type,
        title: title,
        content: content,
        onConfirm: () => _handleAction(type, eventId, userId),
      ),
    );
  }

  Future<void> _handleAction(EventActionType type, String eventId, String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      switch (type) {
        case EventActionType.join:
          await _dinnerEventService.joinEvent(eventId, userId);
          break;
        case EventActionType.cancel:
          await _dinnerEventService.leaveEvent(eventId, userId);
          break;
        case EventActionType.joinWaitlist:
          await _dinnerEventService.joinWaitlist(eventId, userId);
          break;
        case EventActionType.leaveWaitlist:
          await _dinnerEventService.leaveWaitlist(eventId, userId);
          break;
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作成功')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }
}
