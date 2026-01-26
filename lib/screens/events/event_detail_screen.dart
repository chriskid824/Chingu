import 'package:flutter/material.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;
  final DinnerEventModel? initialEvent;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.initialEvent,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Stream<DinnerEventModel?> _eventStream;
  final DinnerEventService _eventService = DinnerEventService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _eventStream = _eventService.getEventStream(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventStream,
      initialData: widget.initialEvent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          if (widget.initialEvent != null && snapshot.connectionState == ConnectionState.waiting) {
             // Show initial data while loading
          } else if (snapshot.connectionState == ConnectionState.active && snapshot.data == null) {
             return Scaffold(
               appBar: AppBar(),
               body: const Center(child: Text('找不到活動或是活動已刪除')),
             );
          } else {
             return const Scaffold(
               body: Center(child: CircularProgressIndicator()),
             );
          }
        }

        // Use initialEvent if stream has no data yet, otherwise stream data
        final event = snapshot.data ?? widget.initialEvent!;
        final isRegistered = event.participantIds.contains(currentUserId);
        final isWaitlisted = event.waitlistIds.contains(currentUserId);
        final isFull = event.participantIds.length >= event.maxParticipants;

        String statusText;
        Color statusColor;
        if (event.status == 'cancelled') {
          statusText = '已取消';
          statusColor = theme.colorScheme.error;
        } else if (event.status == 'completed') {
          statusText = '已結束';
          statusColor = Colors.grey;
        } else if (isRegistered) {
          statusText = '已報名';
          statusColor = chinguTheme?.success ?? Colors.green;
        } else if (isWaitlisted) {
          statusText = '候補中';
          statusColor = Colors.orange;
        } else if (isFull) {
          statusText = '額滿';
          statusColor = theme.colorScheme.secondary;
        } else {
          statusText = '開放報名';
          statusColor = theme.colorScheme.primary;
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
                      // Using a random food image for now
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
                                  Icons.circle,
                                  size: 10,
                                  color: statusColor,
                                ),
                                const SizedBox(width: 6),
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
                        DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW').format(event.dateTime),
                        theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.payments_rounded,
                        '預算範圍',
                        event.budgetRangeText + ' / 人',
                        theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.location_on_rounded,
                        '地點',
                        event.restaurantName != null
                            ? '${event.restaurantName}\n${event.restaurantAddress}'
                            : '${event.city} ${event.district} (餐廳確認中)',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '上限 ${event.maxParticipants} 人\n目前已報名：${event.participantIds.length} 人' +
                        (event.waitlistIds.isNotEmpty ? '\n等候中：${event.waitlistIds.length} 人' : ''),
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      const SizedBox(height: 32),

                      // 只在用戶已報名時顯示聊天和導航
                      if (isRegistered) ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // TODO: Navigate to chat
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
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, isRegistered, isWaitlisted, currentUserId),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    DinnerEventModel event,
    bool isRegistered,
    bool isWaitlisted,
    String? currentUserId,
  ) {
    if (event.status == 'cancelled' || event.status == 'completed') {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isFull = event.participantIds.length >= event.maxParticipants;

    // Check cancellation deadline (24h before event)
    final deadline = event.dateTime.subtract(const Duration(hours: 24));
    final isTooLateToCancel = DateTime.now().isAfter(deadline);

    String buttonText;
    Color? buttonColor;
    bool isDisabled = false;

    if (isRegistered) {
      if (isTooLateToCancel) {
        buttonText = '已過取消期限';
        buttonColor = theme.disabledColor;
        isDisabled = true;
      } else {
        buttonText = '取消報名';
        buttonColor = theme.colorScheme.error;
      }
    } else if (isWaitlisted) {
      buttonText = '退出候補';
      buttonColor = theme.colorScheme.error;
    } else if (isFull) {
      buttonText = '加入等候名單';
      buttonColor = Colors.orange;
    } else {
      buttonText = '立即報名';
      buttonColor = null; // Use default gradient
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
          backgroundColor: buttonColor,
          onPressed: (currentUserId == null || isDisabled) ? null : () {
             _showRegistrationDialog(context, event, isRegistered || isWaitlisted);
          },
        ),
      ),
    );
  }

  void _showRegistrationDialog(BuildContext context, DinnerEventModel event, bool isUnregistering) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return EventRegistrationDialog(
            event: event,
            isRegistering: !isUnregistering,
            isLoading: _isProcessing,
            onConfirm: () async {
              setDialogState(() => _isProcessing = true);
              try {
                final provider = context.read<DinnerEventProvider>();
                bool success;
                if (isUnregistering) {
                  success = await provider.leaveEvent(event.id, currentUserId);
                } else {
                  success = await provider.joinEvent(event.id, currentUserId);
                }

                if (mounted) {
                   Navigator.of(context).pop(); // Close dialog
                   if (success) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(isUnregistering ? '已取消報名' : '報名成功')),
                     );
                   } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text(provider.errorMessage ?? '操作失敗')),
                     );
                   }
                }
              } finally {
                if (mounted) {
                   setDialogState(() => _isProcessing = false);
                }
              }
            },
          );
        }
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
