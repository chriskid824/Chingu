import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late String _eventId;
  late DinnerEventService _eventService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (widget.eventId != null) {
      _eventId = widget.eventId!;
    } else if (args is String) {
      _eventId = args;
    } else {
      // Fallback or Error
      _eventId = '';
    }
    _eventService = DinnerEventService();
  }

  void _handleRegistrationAction(BuildContext context, DinnerEventModel event, String userId) {
    final provider = Provider.of<DinnerEventProvider>(context, listen: false);
    final isRegistered = event.participantIds.contains(userId);
    final isWaitlisted = event.waitlist.contains(userId);
    final isFull = event.currentParticipants >= event.maxParticipants;

    if (isRegistered || isWaitlisted) {
      // Check deadline
      final hoursUntilEvent = event.dateTime.difference(DateTime.now()).inHours;
      if (isRegistered && hoursUntilEvent < 24) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('無法取消'),
            content: const Text('活動開始前 24 小時內無法取消報名。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('了解'),
              ),
            ],
          ),
        );
        return;
      }

      // Cancel Action
      EventRegistrationDialog.show(
        context,
        title: isRegistered ? '取消報名' : '取消候補',
        content: isRegistered
            ? '確定要取消報名此晚餐活動嗎？'
            : '確定要退出候補名單嗎？',
        confirmText: '確定取消',
        isDestructive: true,
        onConfirm: () async {
          final success = await provider.unregisterFromEvent(_eventId, userId);
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已取消')),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(provider.errorMessage ?? '操作失敗')),
            );
          }
        },
      );
    } else {
      // Register Action
      if (isFull) {
        // Join Waitlist
        EventRegistrationDialog.show(
          context,
          title: '加入候補',
          content: '目前名額已滿。確定要加入候補名單嗎？\n如果有空位，將自動遞補並通知您。',
          confirmText: '加入候補',
          onConfirm: () async {
            final status = await provider.registerForEvent(_eventId, userId);
            if (status != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已加入候補名單')),
              );
            }
          },
        );
      } else {
        // Register Directly
        EventRegistrationDialog.show(
          context,
          title: '確認報名',
          content: '確定要報名此晚餐活動嗎？\n報名後請準時出席。',
          confirmText: '確認報名',
          onConfirm: () async {
            final status = await provider.registerForEvent(_eventId, userId);
            if (status != null && mounted) {
              String msg = status == EventRegistrationStatus.registered ? '報名成功！' : '已加入候補';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            }
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = Provider.of<AuthProvider>(context).user?.uid;

    if (_eventId.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到活動 ID')),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(_eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data!;

        return _buildContent(context, event, userId);
      },
    );
  }

  Widget _buildContent(BuildContext context, DinnerEventModel event, String? userId) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');

    final isRegistered = userId != null && event.participantIds.contains(userId);
    final isWaitlisted = userId != null && event.waitlist.contains(userId);

    String statusText = event.statusText;
    Color statusColor = theme.colorScheme.primary;

    if (isRegistered) {
      statusText = '已報名';
      statusColor = chinguTheme?.success ?? Colors.green;
    } else if (isWaitlisted) {
      statusText = '候補中';
      statusColor = chinguTheme?.warning ?? Colors.orange;
    } else if (event.isFull) {
      statusText = '已額滿';
      statusColor = Colors.red;
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
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
                          color: statusColor,
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
                              statusText,
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
                    '${event.city} ${event.district}\n${event.restaurantName ?? "餐廳確認中"}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '${event.currentParticipants} / ${event.maxParticipants} 人\n候補人數: ${event.waitlist.length}',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  if (isRegistered) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                               // Open Chat
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
                        // Navigation button logic can be here
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
          child: userId == null
              ? const SizedBox()
              : _buildActionButton(context, event, userId, isRegistered, isWaitlisted),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DinnerEventModel event, String userId, bool isRegistered, bool isWaitlisted) {
    String text;
    Color? color;
    VoidCallback? onPressed;

    if (isRegistered) {
      text = '取消報名';
      color = Colors.red;
    } else if (isWaitlisted) {
      text = '取消候補';
      color = Colors.red;
    } else if (event.currentParticipants >= event.maxParticipants) {
      text = '加入候補';
    } else {
      text = '立即報名';
    }

    onPressed = () => _handleRegistrationAction(context, event, userId);

    if (color != null) {
        return OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        );
    }

    return GradientButton(
      text: text,
      onPressed: onPressed,
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
