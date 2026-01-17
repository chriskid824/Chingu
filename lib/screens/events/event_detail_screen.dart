import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/services/auth_service.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final eventId = ModalRoute.of(context)?.settings.arguments as String?;
    if (eventId == null) {
      return const Scaffold(body: Center(child: Text('Error: No event ID')));
    }

    final dinnerEventService = DinnerEventService();

    return StreamBuilder<DinnerEventModel?>(
      stream: dinnerEventService.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data == null) {
           return const Scaffold(body: Center(child: Text('活動不存在')));
        }

        final event = snapshot.data!;
        return _EventDetailContent(event: event);
      },
    );
  }
}

class _EventDetailContent extends StatelessWidget {
  final DinnerEventModel event;

  const _EventDetailContent({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;
    final isRegistered = currentUser != null && event.participantIds.contains(currentUser.uid);
    final isWaitlisted = currentUser != null && event.waitlistIds.contains(currentUser.uid);

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
                onPressed: () {
                  // Share logic
                },
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
                          gradient: _getStatusGradient(event.status, chinguTheme),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(event.status),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.statusText,
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
                    '${event.city} ${event.district}\n${event.restaurantName ?? "尚未決定餐廳"}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '${event.maxParticipants} 人（固定）\n目前已報名：${event.currentParticipants} 人' +
                    (event.waitlistIds.isNotEmpty ? '\n候補人數：${event.waitlistIds.length} 人' : ''),
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  if (isRegistered && event.status == 'confirmed')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Navigate to chat
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
                                    '群組聊天',
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
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: _buildActionButton(context, event, isRegistered, isWaitlisted),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, DinnerEventModel event, bool isRegistered, bool isWaitlisted) {
    if (event.status == 'cancelled' || event.dateTime.isBefore(DateTime.now())) {
      return const GradientButton(
        text: '活動已結束/取消',
        onPressed: null, // Disabled
      );
    }

    if (isRegistered) {
      return GradientButton(
        text: '取消報名',
        onPressed: () => _handleUnregister(context, event.id),
        colors: [Colors.red.shade400, Colors.red.shade600],
      );
    }

    if (isWaitlisted) {
      return GradientButton(
        text: '取消候補',
        onPressed: () => _handleUnregister(context, event.id, isWaitlist: true),
        colors: [Colors.orange.shade400, Colors.orange.shade600],
      );
    }

    if (event.isFull) {
       return GradientButton(
        text: '加入候補名單',
        onPressed: () => _handleRegister(context, event.id, isWaitlist: true),
      );
    }

    return GradientButton(
      text: '立即報名',
      onPressed: () => _handleRegister(context, event.id),
    );
  }

  Future<void> _handleRegister(BuildContext context, String eventId, {bool isWaitlist = false}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請先登入')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: isWaitlist ? '加入候補' : '確認報名',
        content: isWaitlist
            ? '目前活動已滿，確認要加入候補名單嗎？若有人取消將自動遞補。'
            : '確認要報名此活動嗎？',
        onConfirm: () {}, // Action is handled in main flow
        confirmText: isWaitlist ? '加入候補' : '確認報名',
      ),
    );

    if (confirmed == true) {
       try {
         await DinnerEventService().registerForEvent(eventId, user.uid);
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功'))
            );
         }
       } catch (e) {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')))
            );
         }
       }
    }
  }

  Future<void> _handleUnregister(BuildContext context, String eventId, {bool isWaitlist = false}) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: isWaitlist ? '取消候補' : '取消報名',
        content: '確認要${isWaitlist ? '取消候補' : '取消報名'}嗎？',
        onConfirm: () {},
        confirmText: '確認取消',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      try {
        await DinnerEventService().unregisterFromEvent(eventId, user.uid);
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已取消'))
            );
         }
      } catch (e) {
         if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')))
            );
         }
      }
    }
  }

  LinearGradient _getStatusGradient(String status, ChinguTheme? theme) {
    switch (status) {
      case 'confirmed':
        return theme?.successGradient ?? const LinearGradient(colors: [Colors.green, Colors.teal]);
      case 'pending':
        return theme?.warningGradient ?? const LinearGradient(colors: [Colors.orange, Colors.deepOrange]);
      case 'cancelled':
        return const LinearGradient(colors: [Colors.grey, Colors.blueGrey]);
      default:
         return theme?.primaryGradient ?? const LinearGradient(colors: [Colors.blue, Colors.blueAccent]);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return Icons.check_circle;
      case 'pending': return Icons.hourglass_empty;
      case 'cancelled': return Icons.cancel;
      default: return Icons.info;
    }
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
