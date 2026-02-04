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
  final String? eventId;

  const EventDetailScreen({super.key, this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();
  DinnerEventModel? _event;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchEvent();
  }

  Future<void> _fetchEvent() async {
    final eventId = widget.eventId ??
        (ModalRoute.of(context)?.settings.arguments as String?);

    if (eventId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = '未提供活動 ID';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final event = await _eventService.getEvent(eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _errorMessage = event == null ? '找不到活動' : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '載入失敗: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleJoinEvent(bool isWaitlist) async {
    if (_event == null) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isActionLoading = true);
    Navigator.of(context).pop(); // Close dialog immediately to show loading on screen

    try {
      await _eventService.joinEvent(_event!.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWaitlist ? '已加入候補名單' : '報名成功！'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchEvent(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  Future<void> _handleLeaveEvent(bool isWaitlist) async {
    if (_event == null) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    setState(() => _isActionLoading = true);
    Navigator.of(context).pop(); // Close dialog

    try {
      await _eventService.leaveEvent(_event!.id, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isWaitlist ? '已退出候補名單' : '已取消報名')),
        );
        _fetchEvent(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失敗: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _showRegistrationDialog(RegistrationDialogType type) {
    if (_event == null) return;

    showDialog(
      context: context,
      barrierDismissible: !_isActionLoading,
      builder: (context) => EventRegistrationDialog(
        type: type,
        eventName: '${_event!.city}${_event!.district}晚餐',
        eventDate: DateFormat('MM/dd HH:mm').format(_event!.dateTime),
        isLoading: false, // Loading handled by parent
        onConfirm: () {
          if (type == RegistrationDialogType.join) _handleJoinEvent(false);
          else if (type == RegistrationDialogType.waitlist) _handleJoinEvent(true);
          else if (type == RegistrationDialogType.cancel) _handleLeaveEvent(false);
          else if (type == RegistrationDialogType.leaveWaitlist) _handleLeaveEvent(true);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = context.watch<AuthProvider>().userModel;

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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: theme.colorScheme.onSurface,
          ),
        ),
        body: Center(child: Text(_errorMessage ?? 'Unknown Error')),
      );
    }

    final event = _event!;
    final isRegistered = user != null && event.participantIds.contains(user.uid);
    final isWaitlisted = user != null && event.waitlist.contains(user.uid);
    final isFull = event.isFull;
    final isClosed = event.isRegistrationClosed;

    String actionButtonText = '立即報名';
    VoidCallback? onActionButtonPressed;
    LinearGradient? buttonGradient;

    if (isRegistered) {
      actionButtonText = '取消報名';
      onActionButtonPressed = () => _showRegistrationDialog(RegistrationDialogType.cancel);
      buttonGradient = chinguTheme?.errorGradient; // Red for cancel
    } else if (isWaitlisted) {
      actionButtonText = '退出候補';
      onActionButtonPressed = () => _showRegistrationDialog(RegistrationDialogType.leaveWaitlist);
      buttonGradient = chinguTheme?.errorGradient;
    } else if (isClosed) {
      actionButtonText = '報名已截止';
      onActionButtonPressed = null;
    } else if (isFull) {
      actionButtonText = '加入候補';
      onActionButtonPressed = () => _showRegistrationDialog(RegistrationDialogType.waitlist);
      buttonGradient = chinguTheme?.warningGradient; // Orange for waitlist
    } else {
      actionButtonText = '立即報名';
      onActionButtonPressed = () => _showRegistrationDialog(RegistrationDialogType.join);
      buttonGradient = chinguTheme?.primaryGradient; // Default primary
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
              const SizedBox(width: 8),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.more_vert_rounded,
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
                          '${event.city}${event.district}晚餐聚會',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isRegistered)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.successGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '已報名',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                      else if (isWaitlisted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.warningGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '候補中',
                              style: TextStyle(
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
                    event.restaurantAddress ?? '${event.city}${event.district} (餐廳安排中)',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '6 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitlist.isNotEmpty ? ' (候補 ${event.waitlist.length} 人)' : ''}',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isRegistered ? () {} : null,
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
                                color: isRegistered ? theme.colorScheme.primary : theme.disabledColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '聊天',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isRegistered ? theme.colorScheme.primary : theme.disabledColor,
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
                            gradient: isRegistered ? chinguTheme?.primaryGradient : null,
                            color: isRegistered ? null : theme.disabledColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isRegistered ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ] : [],
                          ),
                          child: ElevatedButton(
                            onPressed: isRegistered ? () {} : null,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_rounded, color: isRegistered ? Colors.white : theme.disabledColor),
                                const SizedBox(width: 8),
                                Text(
                                  '導航',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isRegistered ? Colors.white : theme.disabledColor,
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
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: GradientButton(
            text: actionButtonText,
            onPressed: onActionButtonPressed ?? () {},
            gradient: onActionButtonPressed == null ? LinearGradient(colors: [theme.disabledColor, theme.disabledColor]) : buttonGradient,
            isLoading: _isActionLoading,
          ),
        ),
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
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
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
