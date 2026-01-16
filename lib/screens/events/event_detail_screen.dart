import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  String? _eventId;
  bool _isActionLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_eventId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is String) {
        _eventId = args;
      }
    }
  }

  Future<void> _handleJoin(DinnerEventModel event) async {
    if (_userId.isEmpty) return; // Should show login prompt

    try {
      setState(() => _isActionLoading = true);
      // 檢查時間衝突
      await _eventService.checkTimeConflict(_userId, event.dateTime);
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('無法報名: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }

    final isFull = event.participantIds.length >= event.maxParticipants;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => isFull
          ? EventRegistrationDialog.waitlist(
              currentWaitlistCount: event.waitingListIds.length,
              isLoading: _isActionLoading,
              onConfirm: () => _performRegistration(event.id),
            )
          : EventRegistrationDialog.join(
              isLoading: _isActionLoading,
              onConfirm: () => _performRegistration(event.id),
            ),
    );
  }

  Future<void> _handleCancel(DinnerEventModel event) async {
    final now = DateTime.now();
    final deadline = event.dateTime.subtract(const Duration(hours: 24));
    final isWithin24Hours = now.isAfter(deadline);

    if (isWithin24Hours) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('無法取消'),
          content: const Text('距離活動開始已不足 24 小時，無法取消報名。\n請務必準時出席，以免影響您的信用評分。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('了解'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog.cancel(
        isWithin24Hours: isWithin24Hours,
        isLoading: _isActionLoading,
        onConfirm: () => _performCancellation(event.id),
      ),
    );
  }

  Future<void> _performRegistration(String eventId) async {
    setState(() => _isActionLoading = true);
    // Close dialog first or keep it open with loading?
    // The dialog has isLoading prop, but here we are in the dialog's callback.
    // To update dialog state, we need state management or StatefulBuilder in dialog.
    // For simplicity, we pop dialog and show loading overlay or just loading on screen.
    // Better: Close dialog, show global loading or snackbar.
    Navigator.of(context).pop();

    try {
      final status = await _eventService.registerForEvent(eventId, _userId);

      if (mounted) {
        String message = status == EventRegistrationStatus.registered
            ? '報名成功！'
            : '已加入等候清單';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _performCancellation(String eventId) async {
    setState(() => _isActionLoading = true);
    Navigator.of(context).pop();

    try {
      await _eventService.unregisterFromEvent(eventId, _userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消報名')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (_eventId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('無效的活動 ID')),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(_eventId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('找不到活動資訊: ${snapshot.error}')),
          );
        }

        final event = snapshot.data!;
        final isParticipant = event.participantIds.contains(_userId);
        final isWaitlist = event.waitingListIds.contains(_userId);
        final isFull = event.participantIds.length >= event.maxParticipants;
        final isPast = event.dateTime.isBefore(DateTime.now());

        // Formats
        final dateFormat = DateFormat('yyyy年MM月dd日 (E)', 'zh_TW');
        final timeFormat = DateFormat('HH:mm');

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
                              event.budgetRangeText,
                              style: const TextStyle(
                                fontSize: 24,
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
                              '${event.city}${event.district}晚餐聚會',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isParticipant ? chinguTheme?.successGradient : null,
                              color: isParticipant ? null : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isParticipant ? Icons.check_circle : Icons.info_outline,
                                  size: 16,
                                  color: isParticipant ? Colors.white : theme.colorScheme.onSurface,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isParticipant ? '已報名' : (isWaitlist ? '排隊中' : event.statusText),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isParticipant ? Colors.white : theme.colorScheme.onSurface,
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
                        '${dateFormat.format(event.dateTime)}\n${timeFormat.format(event.dateTime)}',
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
                        '${event.city} ${event.district}',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人\n等候人數：${event.waitingListIds.length} 人',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (isParticipant) ...[
                         const SizedBox(height: 32),
                         _buildActionButtons(context, theme, chinguTheme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: (!isPast && !event.status.contains('cancelled')) ? Container(
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
              child: _buildMainButton(event, isParticipant, isWaitlist, isFull, theme, chinguTheme),
            ),
          ) : null,
        );
      },
    );
  }

  Widget _buildMainButton(
    DinnerEventModel event,
    bool isParticipant,
    bool isWaitlist,
    bool isFull,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    if (isParticipant || isWaitlist) {
      return OutlinedButton(
        onPressed: _isActionLoading ? null : () => _handleCancel(event),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _isActionLoading ? '處理中...' : '取消報名',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    String buttonText = '立即報名';
    Color? color;
    if (isFull) {
      buttonText = '加入等候清單';
      color = theme.colorScheme.secondary;
    }

    return GradientButton(
      text: _isActionLoading ? '處理中...' : buttonText,
      onPressed: _isActionLoading ? null : () => _handleJoin(event),
      // gradient: isFull ? null : null, // Uses default primary if null
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
    return Row(
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
