import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/widgets/loading_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  final String? eventId;
  final DinnerEventModel? event;

  const EventDetailScreen({
    Key? key,
    this.eventId,
    this.event,
  }) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DinnerEventModel? _event;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initEvent();
  }

  Future<void> _initEvent() async {
    if (widget.event != null) {
      setState(() {
        _event = widget.event;
        _isLoading = false;
      });
      // Refresh to get latest status (waitlist numbers, etc)
      _fetchLatest();
    } else if (widget.eventId != null) {
      _fetchLatest();
    }
  }

  Future<void> _fetchLatest() async {
    final provider = Provider.of<DinnerEventProvider>(context, listen: false);
    final id = widget.eventId ?? widget.event?.id;
    if (id != null) {
      final latest = await provider.getEventById(id);
      if (mounted) {
        setState(() {
          _event = latest;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegistrationAction(UserModel user) async {
    if (_event == null) return;

    final provider = Provider.of<DinnerEventProvider>(context, listen: false);
    final status = _event!.getUserRegistrationStatus(user.uid);

    // Show confirmation dialog
    final confirmed = await EventRegistrationDialog.show(
      context,
      event: _event!,
      currentStatus: status,
      onConfirm: () {}, // Handled below
    );

    if (confirmed == true) {
      if (!mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const LoadingDialog(message: '處理中...'),
      );

      bool success = false;
      if (status == EventRegistrationStatus.registered || status == EventRegistrationStatus.waitlist) {
        success = await provider.leaveEvent(_event!.id, user.uid);
      } else {
        success = await provider.joinEvent(_event!.id, user.uid);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (success) {
           _fetchLatest(); // Refresh UI
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('操作成功'))
           );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(provider.errorMessage ?? '操作失敗'),
               backgroundColor: Theme.of(context).colorScheme.error,
             )
           );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>()!;
    final user = Provider.of<AuthProvider>(context).user;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(),
        body: const Center(child: Text('找不到活動')),
      );
    }

    final event = _event!;
    final userStatus = user != null ? event.getUserRegistrationStatus(user.uid) : EventRegistrationStatus.none;

    String actionButtonText = '立即報名';
    Color? actionButtonColor;

    if (userStatus == EventRegistrationStatus.registered) {
      actionButtonText = '取消報名';
      actionButtonColor = theme.colorScheme.error;
    } else if (userStatus == EventRegistrationStatus.waitlist) {
      actionButtonText = '退出候補';
      actionButtonColor = theme.colorScheme.error;
    } else if (event.isFull) {
      actionButtonText = '加入候補名單';
      actionButtonColor = chinguTheme.warning;
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
                          gradient: event.status == 'confirmed' ? chinguTheme.successGradient : null,
                          color: event.status != 'confirmed' ? theme.colorScheme.surfaceContainerHighest : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              event.status == 'confirmed' ? Icons.check_circle : Icons.access_time_filled,
                              size: 16,
                              color: event.status == 'confirmed' ? Colors.white : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.statusText,
                              style: TextStyle(
                                fontSize: 13,
                                color: event.status == 'confirmed' ? Colors.white : theme.colorScheme.onSurfaceVariant,
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
                    event.dateTime.toString().substring(0, 16),
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
                    chinguTheme.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  
                  // Participants Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('參加人數', style: theme.textTheme.titleMedium),
                            Text(
                              '${event.participantIds.length} / ${event.maxParticipants}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: event.participantIds.length / event.maxParticipants,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                            event.isFull ? chinguTheme.warning : theme.colorScheme.primary
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        if (event.waitingList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.hourglass_empty_rounded, size: 16, color: chinguTheme.warning),
                              const SizedBox(width: 4),
                              Text(
                                '候補人數: ${event.waitingList.length} 人',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: chinguTheme.warning,
                                ),
                              ),
                            ],
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  if (user != null)
                    SafeArea(
                      top: false,
                      child: GradientButton(
                        text: actionButtonText,
                        onPressed: () => _handleRegistrationAction(user),
                        gradient: actionButtonColor != null
                            ? LinearGradient(colors: [actionButtonColor, actionButtonColor])
                            : null, // Use default gradient if null
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
