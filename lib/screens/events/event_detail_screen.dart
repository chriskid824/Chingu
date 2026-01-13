import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/widgets/loading_dialog.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DinnerEventModel? _event;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is DinnerEventModel) {
      setState(() => _event = args);
    } else if (args is String) {
      // Fetch by ID
      setState(() => _isLoading = true);
      final event = await Provider.of<DinnerEventProvider>(context, listen: false)
          .getEventById(args);
      setState(() {
        _event = event;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegistrationAction(BuildContext context, EventRegistrationAction action) async {
    if (_event == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final eventProvider = Provider.of<DinnerEventProvider>(context, listen: false);
    final userId = authProvider.user?.uid;

    if (userId == null) return;

    String title;
    String message;

    switch (action) {
      case EventRegistrationAction.register:
        title = '確認報名';
        message = '確定要報名此活動嗎？系統將為您保留名額。';
        break;
      case EventRegistrationAction.joinWaitlist:
        title = '加入候補';
        message = '目前人數已滿，確定要加入候補名單嗎？若有名額釋出，將自動為您候補。';
        break;
      case EventRegistrationAction.cancelRegistration:
        title = '取消報名';
        message = '確定要取消報名嗎？距離活動開始時間越近，可能會影響您的信用評分。';
        break;
      case EventRegistrationAction.leaveWaitlist:
        title = '取消候補';
        message = '確定要退出候補名單嗎？';
        break;
    }

    final confirmed = await EventRegistrationDialog.show(
      context: context,
      title: title,
      message: message,
      action: action,
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
      if (action == EventRegistrationAction.register || action == EventRegistrationAction.joinWaitlist) {
        success = await eventProvider.joinEvent(_event!.id, userId);
      } else {
        success = await eventProvider.leaveEvent(_event!.id, userId);
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      if (success) {
        // Refresh event data
        await _loadEvent();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(action == EventRegistrationAction.cancelRegistration || action == EventRegistrationAction.leaveWaitlist ? '已取消' : '操作成功')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(eventProvider.errorMessage ?? '操作失敗')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('活動詳情')),
        body: const Center(child: Text('找不到活動')),
      );
    }

    final event = _event!;
    final isParticipant = userId != null && event.participantIds.contains(userId);
    final isWaitlisted = userId != null && event.waitingList.contains(userId);
    final isFull = event.isFull;
    final isDeadlinePassed = DateTime.now().isAfter(event.registrationDeadline);
    final isCancelled = event.status == 'cancelled';

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
                          '6人晚餐聚會',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusChip(context, event, isParticipant, isWaitlisted),
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
                    event.budgetRangeText + ' / 人',
                    theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.location_on_rounded,
                    '地點',
                    '${event.city}${event.district}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '6 人（固定）\n目前已報名：${event.participantIds.length} 人',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  if (event.notes != null && event.notes!.isNotEmpty) ...[
                     const SizedBox(height: 12),
                     _buildInfoCard(
                      context,
                      Icons.note_rounded,
                      '備註',
                      event.notes!,
                      theme.colorScheme.onSurface,
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  if (isParticipant)
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
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isCancelled ? null : Container(
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
          child: _buildActionButton(context, event, isParticipant, isWaitlisted, isFull, isDeadlinePassed),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, DinnerEventModel event, bool isParticipant, bool isWaitlisted) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String text;
    Color color;
    IconData icon;

    if (event.status == 'cancelled') {
      text = '已取消';
      color = theme.colorScheme.error;
      icon = Icons.cancel;
    } else if (event.status == 'completed') {
      text = '已完成';
      color = theme.colorScheme.secondary;
      icon = Icons.check_circle;
    } else if (isParticipant) {
      text = '已報名';
      color = chinguTheme?.success ?? Colors.green;
      icon = Icons.check_circle;
    } else if (isWaitlisted) {
      text = '候補中';
      color = chinguTheme?.warning ?? Colors.orange;
      icon = Icons.hourglass_top;
    } else if (event.status == 'confirmed') {
      text = '已成團';
      color = theme.colorScheme.primary;
      icon = Icons.group;
    } else {
      text = '等待配對';
      color = theme.colorScheme.primary.withOpacity(0.7);
      icon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
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

  Widget _buildActionButton(
    BuildContext context,
    DinnerEventModel event,
    bool isParticipant,
    bool isWaitlisted,
    bool isFull,
    bool isDeadlinePassed
  ) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    if (isParticipant) {
      return OutlinedButton(
        onPressed: () => _handleRegistrationAction(context, EventRegistrationAction.cancelRegistration),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          '取消報名',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: () => _handleRegistrationAction(context, EventRegistrationAction.leaveWaitlist),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          '取消候補',
          style: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isDeadlinePassed) {
       return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.disabledColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '報名已截止',
          style: TextStyle(
            color: theme.disabledColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isFull) {
      return GradientButton(
        text: '加入候補名單',
        onPressed: () => _handleRegistrationAction(context, EventRegistrationAction.joinWaitlist),
        colors: [chinguTheme?.warning ?? Colors.orange, (chinguTheme?.warning ?? Colors.orange).withOpacity(0.8)],
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _handleRegistrationAction(context, EventRegistrationAction.register),
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
