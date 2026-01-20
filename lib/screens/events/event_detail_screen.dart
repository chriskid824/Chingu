import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  DinnerEventModel? _event;
  bool _isLoading = false;
  final DinnerEventService _eventService = DinnerEventService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_event == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is DinnerEventModel) {
        _event = args;
        // 為了確保數據最新，我們可以在後台刷新
        _refreshEvent(args.id);
      } else if (args is Map && args.containsKey('id')) {
        _loadEvent(args['id']);
      }
    }
  }

  Future<void> _refreshEvent(String eventId) async {
    try {
      final event = await _eventService.getEvent(eventId);
      if (mounted && event != null) {
        setState(() => _event = event);
      }
    } catch (e) {
      debugPrint('刷新活動失敗: $e');
    }
  }

  Future<void> _loadEvent(String eventId) async {
    setState(() => _isLoading = true);
    try {
      final event = await _eventService.getEvent(eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('載入活動失敗: $e')),
        );
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (_event == null) return;
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: '確認報名',
        message: '您確定要報名參加這場晚餐嗎？\n如果是候補，我們將在有名額時通知您。',
        onConfirm: () async {
          try {
            setState(() => _isLoading = true);
            final status = await _eventService.registerForEvent(_event!.id, userId);

            await _refreshEvent(_event!.id);

            if (mounted) {
              setState(() => _isLoading = false);
              String message = status == EventRegistrationStatus.registered
                  ? '報名成功！'
                  : '已加入候補名單';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('報名失敗: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _handleCancellation() async {
    if (_event == null) return;
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: '取消報名',
        message: '您確定要取消報名嗎？\n活動前24小時內取消可能會被記錄爽約。',
        confirmText: '確認取消',
        isDestructive: true,
        onConfirm: () async {
          try {
            setState(() => _isLoading = true);
            await _eventService.unregisterFromEvent(_event!.id, userId);

            await _refreshEvent(_event!.id);

            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已取消報名')),
              );
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('取消失敗: $e')),
              );
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
    final userId = context.read<AuthProvider>().uid;

    if (_isLoading && _event == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到活動')),
      );
    }

    // Determine status
    bool isParticipant = _event!.participantIds.contains(userId);
    bool isWaitlisted = _event!.waitingList.contains(userId);
    bool isFull = _event!.isFull;
    bool isPast = _event!.dateTime.isBefore(DateTime.now());

    String statusLabel = '等待配對';
    Color statusColor = theme.colorScheme.primary;
    if (_event!.status == 'confirmed') {
      statusLabel = '已確認';
      statusColor = chinguTheme?.success ?? Colors.green;
    } else if (_event!.status == 'cancelled') {
      statusLabel = '已取消';
      statusColor = theme.colorScheme.error;
    } else if (_event!.status == 'completed') {
      statusLabel = '已完成';
      statusColor = Colors.grey;
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
                          '${_event!.city} ${_event!.district} 晚餐',
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
                              Icons.check_circle,
                              size: 16,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
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
                    DateFormat('yyyy/MM/dd (E) HH:mm', 'zh_TW').format(_event!.dateTime),
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.payments_rounded,
                    '預算範圍',
                    _event!.budgetRangeText,
                    theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.location_on_rounded,
                    '地點',
                    '${_event!.city} ${_event!.district}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '${_event!.currentParticipants} / ${_event!.maxParticipants} 人\n等候清單: ${_event!.waitingList.length} 人',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (isParticipant || isWaitlisted) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Chat navigation logic here
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
                      ],
                    ),
                    const SizedBox(height: 12),
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
          child: _buildActionButton(isParticipant, isWaitlisted, isFull, isPast),
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isParticipant, bool isWaitlisted, bool isFull, bool isPast) {
    if (isPast) {
      return GradientButton(
        text: '活動已結束',
        onPressed: () {},
        isEnabled: false,
      );
    }

    if (isParticipant) {
      return OutlinedButton(
        onPressed: _handleCancellation,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '取消報名',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isWaitlisted) {
      return OutlinedButton(
        onPressed: _handleCancellation,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '取消候補',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isFull) {
      return GradientButton(
        text: '加入候補名單',
        onPressed: _handleRegistration,
        isLoading: _isLoading,
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: _handleRegistration,
      isLoading: _isLoading,
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
