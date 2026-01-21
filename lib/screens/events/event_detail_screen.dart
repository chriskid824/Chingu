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
  final String? eventId;
  final DinnerEventModel? event;

  const EventDetailScreen({
    super.key,
    this.eventId,
    this.event,
  }) : assert(eventId != null || event != null, 'Either eventId or event must be provided');

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _dinnerEventService = DinnerEventService();
  late Stream<DinnerEventModel?> _eventStream;
  DinnerEventModel? _initialEvent;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialEvent = widget.event;
    final id = widget.eventId ?? widget.event?.id;
    if (id != null) {
      _eventStream = _dinnerEventService.getEventStream(id);
    }
  }

  Future<void> _handleRegistrationAction(
    BuildContext context,
    DinnerEventModel event,
    EventRegistrationStatus status,
    String userId
  ) async {
    RegistrationAction action;
    String title;
    String message;

    if (status == EventRegistrationStatus.registered) {
      action = RegistrationAction.leave;
      title = '取消報名';
      message = '您確定要取消這次的晚餐聚會嗎？\n如果是活動前 24 小時內取消，將無法退還點數並記錄一次爽約。';
    } else if (status == EventRegistrationStatus.waitlist) {
      action = RegistrationAction.leaveWaitlist;
      title = '取消候補';
      message = '您確定要取消候補嗎？';
    } else {
      if (event.isFull) {
        action = RegistrationAction.joinWaitlist;
        title = '加入候補名單';
        message = '目前活動人數已滿，您可以加入候補名單。\n如果有參加者取消，您將有機會遞補參加。';
      } else {
        action = RegistrationAction.join;
        title = '確認報名';
        message = '您確定要報名這次的晚餐聚會嗎？\n報名成功後請準時出席。';
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return EventRegistrationDialog(
            action: action,
            title: title,
            message: message,
            isLoading: _isLoading,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: () async {
              setState(() => _isLoading = true);
              try {
                if (action == RegistrationAction.join || action == RegistrationAction.joinWaitlist) {
                  await _dinnerEventService.registerForEvent(event.id, userId);
                } else {
                  await _dinnerEventService.unregisterFromEvent(event.id, userId);
                }
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(
                      action == RegistrationAction.join ? '報名成功！' :
                      action == RegistrationAction.joinWaitlist ? '已加入候補名單' : '已取消'
                    )),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventStream,
      initialData: _initialEvent,
      builder: (context, snapshot) {
        final event = snapshot.data;

        if (event == null) {
           if (snapshot.connectionState == ConnectionState.waiting) {
             return const Scaffold(body: Center(child: CircularProgressIndicator()));
           }
           return Scaffold(
             appBar: AppBar(),
             body: const Center(child: Text('活動不存在或已被刪除')),
           );
        }

        final userStatus = event.getUserRegistrationStatus(userId);

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
                        '${event.city} ${event.district}', // 實際餐廳地址在確認後顯示
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.currentParticipants} 人${event.waitlist.isNotEmpty ? '\n候補人數：${event.waitlist.length} 人' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (userStatus == EventRegistrationStatus.registered) ...[
                        const SizedBox(height: 32),
                        Row(
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
              child: _buildActionButton(context, event, userStatus, userId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, DinnerEventModel event, EventRegistrationStatus status, String userId) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String text;
    VoidCallback? onPressed;
    LinearGradient? gradient;

    if (status == EventRegistrationStatus.registered) {
      text = '取消報名';
      gradient = LinearGradient(colors: [theme.colorScheme.error, theme.colorScheme.error.withOpacity(0.8)]);
      onPressed = () => _handleRegistrationAction(context, event, status, userId);
    } else if (status == EventRegistrationStatus.waitlist) {
      text = '取消候補';
      gradient = LinearGradient(colors: [theme.colorScheme.error.withOpacity(0.8), theme.colorScheme.error.withOpacity(0.6)]);
      onPressed = () => _handleRegistrationAction(context, event, status, userId);
    } else {
      // Not registered
      if (event.isFull) {
        text = '加入候補';
        gradient = LinearGradient(colors: [chinguTheme?.warning ?? Colors.orange, (chinguTheme?.warning ?? Colors.orange).withOpacity(0.8)]);
        onPressed = () => _handleRegistrationAction(context, event, status, userId);
      } else {
        text = '立即報名';
        onPressed = () => _handleRegistrationAction(context, event, status, userId);
      }
    }

    // Check 24h rule for disabling cancellation
    if (status == EventRegistrationStatus.registered) {
       final now = DateTime.now();
       if (event.dateTime.difference(now).inHours < 24) {
         // Maybe just show it but dialog says warning?
         // Or disable it? Prompt says "不可取消"
         // I'll disable it here visually or handle in dialog.
         // Let's keep it enabled but dialog handles logic/warning,
         // BUT wait, if I can't cancel, I shouldn't be able to click?
         // Let's disable and change text.
         text = '已截止取消';
         onPressed = null;
         gradient = LinearGradient(colors: [Colors.grey, Colors.grey.withOpacity(0.8)]);
       }
    }

    return GradientButton(
      text: text,
      onPressed: onPressed ?? () {},
      gradient: gradient,
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color color;
    String text;

    switch (status) {
      case 'confirmed':
        color = chinguTheme?.success ?? Colors.green;
        text = '已確認';
        break;
      case 'pending':
        color = chinguTheme?.warning ?? Colors.orange;
        text = '等待配對';
        break;
      case 'cancelled':
        color = theme.colorScheme.error;
        text = '已取消';
        break;
      case 'completed':
        color = Colors.blue;
        text = '已完成';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
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
