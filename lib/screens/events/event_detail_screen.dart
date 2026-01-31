import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
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
        // Handle error or pop
      }
      _initialized = true;
    }
  }

  Future<void> _handleRegistrationAction(DinnerEventModel event, EventRegistrationStatus status) async {
    final userId = context.read<AuthProvider>().currentUser?.uid;
    if (userId == null) return;

    RegistrationAction action;
    if (status == EventRegistrationStatus.registered || status == EventRegistrationStatus.waitlist) {
      action = RegistrationAction.cancel;
    } else if (event.isFull) {
      action = RegistrationAction.waitlist;
    } else {
      action = RegistrationAction.register;
    }

    final confirm = await EventRegistrationDialog.show(
      context,
      action: action,
      eventTitle: '${event.city} ${event.district} 晚餐聚會',
      eventDate: event.dateTime,
    );

    if (confirm == true && mounted) {
      try {
        if (action == RegistrationAction.cancel) {
          await _eventService.unregisterFromEvent(event.id, userId);
        } else {
          await _eventService.registerForEvent(event.id, userId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(action == RegistrationAction.cancel ? '已取消報名' : '報名成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox();

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(_eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('無法載入活動資訊')),
          );
        }

        final event = snapshot.data!;
        final user = context.watch<AuthProvider>().currentUser;
        final registrationStatus = user != null
            ? event.getUserRegistrationStatus(user.uid)
            : EventRegistrationStatus.none;

        // Status Badge Logic
        String statusText = event.statusText;
        Color statusColor = theme.colorScheme.primary;

        if (event.status == 'confirmed') {
          statusText = '已成團';
          statusColor = chinguTheme?.success ?? Colors.green;
        } else if (event.status == 'cancelled') {
          statusText = '已取消';
          statusColor = theme.colorScheme.error;
        }

        if (registrationStatus == EventRegistrationStatus.registered) {
          statusText = '已報名';
          statusColor = chinguTheme?.success ?? Colors.green;
        } else if (registrationStatus == EventRegistrationStatus.waitlist) {
          statusText = '候補中';
          statusColor = chinguTheme?.warning ?? Colors.orange;
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
                            const SizedBox(height: 12),
                            Text(
                              '${event.maxParticipants}人晚餐',
                              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
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
                              '${event.city} ${event.district} 聚會',
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
                        event.restaurantName != null
                            ? '${event.restaurantName}\n${event.restaurantAddress}'
                            : '系統配對中 (確認後通知)',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitlistCount > 0 ? '\n候補人數：${event.waitlistCount} 人' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (registrationStatus == EventRegistrationStatus.registered) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // Chat Logic
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
                            // ... Navigation button if needed
                          ],
                        ),
                      ],
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, registrationStatus),
        );
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, EventRegistrationStatus status) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Determine button state
    String buttonText = '立即報名';
    Color buttonColor = theme.colorScheme.primary;
    bool isDisabled = false;

    if (event.status == 'cancelled' || event.status == 'completed') {
      buttonText = '活動已結束';
      isDisabled = true;
      buttonColor = Colors.grey;
    } else if (status == EventRegistrationStatus.registered) {
      buttonText = '取消報名';
      buttonColor = theme.colorScheme.error;
    } else if (status == EventRegistrationStatus.waitlist) {
      buttonText = '取消候補';
      buttonColor = theme.colorScheme.error;
    } else if (event.isFull) {
      buttonText = '加入候補名單';
      buttonColor = chinguTheme?.warning ?? Colors.orange;
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
        child: isDisabled
          ? ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: Text(buttonText),
            )
          : GradientButton(
              text: buttonText,
              onPressed: () => _handleRegistrationAction(event, status),
              gradient: status == EventRegistrationStatus.registered || status == EventRegistrationStatus.waitlist
                  ? LinearGradient(colors: [buttonColor, buttonColor.withOpacity(0.8)]) // Red for cancel
                  : (event.isFull ? LinearGradient(colors: [buttonColor, buttonColor.withOpacity(0.8)]) : null), // Custom gradient for waitlist, default for register
            ),
      ),
    );
  }
  
  Widget _buildInfoCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
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
