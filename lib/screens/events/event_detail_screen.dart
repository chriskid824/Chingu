import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId; // Made nullable to support legacy route usage if needed, but logic requires it

  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  DinnerEventModel? _event;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  // Handle arguments from named route if eventId not passed directly
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.eventId == null && _event == null && _isLoading) {
       final args = ModalRoute.of(context)?.settings.arguments;
       if (args is String) {
         _fetchEvent(args);
       } else {
         setState(() {
           _isLoading = false;
           _errorMessage = '無效的活動 ID';
         });
       }
    }
  }

  Future<void> _loadEvent() async {
    if (widget.eventId != null) {
      _fetchEvent(widget.eventId!);
    }
  }

  Future<void> _fetchEvent(String id) async {
    try {
      final event = await _eventService.getEvent(id);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '無法載入活動: $e';
        });
      }
    }
  }

  Future<void> _handleRegistrationAction() async {
    if (_event == null) return;

    final bool isParticipant = _event!.participantIds.contains(_currentUserId);
    final bool isWaitlisted = _event!.waitingListIds.contains(_currentUserId);
    final bool isFull = _event!.isFull;

    RegistrationDialogType type;
    if (isParticipant || isWaitlisted) {
      type = RegistrationDialogType.cancel;
    } else if (isFull) {
      type = RegistrationDialogType.joinWaitlist;
    } else {
      type = RegistrationDialogType.register;
    }

    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        type: type,
        isLoading: _isActionLoading,
        onConfirm: () async {
          setState(() => _isActionLoading = true);
          Navigator.of(context).pop(); // Close dialog

          try {
            if (type == RegistrationDialogType.cancel) {
              await _eventService.unregisterFromEvent(_event!.id, _currentUserId);
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已取消報名')),
                );
              }
            } else {
              await _eventService.registerForEvent(_event!.id, _currentUserId);
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(type == RegistrationDialogType.joinWaitlist ? '已加入候補' : '報名成功')),
                );
              }
            }
            // Refresh
            await _fetchEvent(_event!.id);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isActionLoading = false);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _event == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: Center(child: Text(_errorMessage ?? '活動不存在')),
      );
    }

    final event = _event!;
    final isParticipant = event.participantIds.contains(_currentUserId);
    final isWaitlisted = event.waitingListIds.contains(_currentUserId);
    final isFull = event.isFull;
    final isPast = event.status == 'completed' || event.status == 'cancelled' || event.dateTime.isBefore(DateTime.now());

    String statusText = event.statusText;
    Color statusColor = theme.colorScheme.primary;
    if (event.status == 'cancelled') {
      statusColor = theme.colorScheme.error;
    } else if (event.status == 'confirmed') {
      statusColor = chinguTheme?.success ?? Colors.green;
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
                   Container(
                    color: theme.colorScheme.surfaceContainerHighest, // Placeholder if no image
                    child: const Icon(Icons.restaurant, size: 64, color: Colors.grey),
                   ),
                  // If we had an image URL in the model, use it here.
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
                          '${event.city}${event.district} 晚餐聚會',
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
                    '${event.city} ${event.district} (餐廳確認後通知)',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '上限 ${event.maxParticipants} 人\n目前已報名：${event.participantIds.length} 人${event.waitingListIds.isNotEmpty ? '\n候補人數：${event.waitingListIds.length} 人' : ''}',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (isParticipant) ...[
                     Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {}, // Open Chat
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('聊天室'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!isPast)
                    SafeArea(
                      child: GradientButton(
                        text: isParticipant
                            ? '取消報名'
                            : isWaitlisted
                                ? '取消候補'
                                : isFull
                                    ? '加入候補'
                                    : '立即報名',
                        onPressed: _isActionLoading ? null : _handleRegistrationAction,
                        isLoading: _isActionLoading,
                        gradient: (isParticipant || isWaitlisted)
                            ? LinearGradient(
                                colors: [
                                  theme.colorScheme.error.withOpacity(0.8),
                                  theme.colorScheme.error,
                                ],
                              )
                            : isFull
                                ? LinearGradient( // Waitlist color (Orange-ish)
                                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                                  )
                                : null, // Default Primary
                      ),
                    ),
                ],
              ),
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
