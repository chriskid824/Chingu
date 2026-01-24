import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class EventDetailScreen extends StatelessWidget {
  final String? eventId; // Make it nullable to avoid breaking if called without ID in legacy code, but we should enforce it.

  const EventDetailScreen({super.key, this.eventId});
  
  @override
  Widget build(BuildContext context) {
    if (eventId == null) {
      return const Scaffold(body: Center(child: Text('Error: No Event ID provided')));
    }

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final dinnerEventService = DinnerEventService();
    final userId = context.watch<AuthProvider>().user?.uid;

    return StreamBuilder<DinnerEventModel?>(
      stream: dinnerEventService.getEventStream(eventId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text('無法載入活動詳情')));
        }

        final event = snapshot.data!;

        // Determine user status
        final isRegistered = userId != null && event.isUserRegistered(userId);
        final isWaitlisted = userId != null && event.isUserWaitlisted(userId);

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
                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80', // TODO: Use dynamic image based on category/city
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
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
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
                          _buildStatusBadge(context, event, isRegistered, isWaitlisted),
                        ],
                      ),
                      const SizedBox(height: 24),

                      _buildInfoCard(
                        context,
                        Icons.calendar_today_rounded,
                        '日期時間',
                        DateFormat('yyyy年MM月dd日 (E) HH:mm', 'zh_TW').format(event.dateTime),
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
                        '${event.city} ${event.district}\n(詳細餐廳資訊將於配對成功後通知)',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.currentParticipants} / ${event.maxParticipants} 人\n'
                        '${event.waitlistCount > 0 ? '目前候補：${event.waitlistCount} 人' : '目前無候補'}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (event.notes != null && event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('備註', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(event.notes!, style: theme.textTheme.bodyMedium),
                      ],

                      // Only show actions like Chat/Navigate if confirmed and user is participant
                      if (event.status == 'confirmed' && isRegistered) ...[
                         const SizedBox(height: 32),
                         _buildParticipantActions(context, theme, chinguTheme),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(
            context,
            event,
            isRegistered,
            isWaitlisted,
            userId,
            dinnerEventService
          ),
        );
      }
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    DinnerEventModel event,
    bool isRegistered,
    bool isWaitlisted
  ) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String text = event.statusText;
    Color color = Colors.grey;
    IconData icon = Icons.info;

    if (isRegistered) {
      text = '已報名';
      color = chinguTheme?.success ?? Colors.green;
      icon = Icons.check_circle;
    } else if (isWaitlisted) {
      text = '候補中';
      color = chinguTheme?.warning ?? Colors.orange;
      icon = Icons.hourglass_top;
    } else if (event.isFull) {
      text = '已滿員';
      color = theme.colorScheme.error;
      icon = Icons.group_off;
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

  Widget _buildBottomBar(
    BuildContext context,
    DinnerEventModel event,
    bool isRegistered,
    bool isWaitlisted,
    String? userId,
    DinnerEventService service,
  ) {
    final theme = Theme.of(context);

    // 如果沒有登入，或活動已結束，或已取消，顯示對應狀態或不顯示按鈕
    final isPast = event.dateTime.isBefore(DateTime.now());
    if (userId == null || isPast || event.status == 'cancelled') {
       return const SizedBox.shrink();
    }

    String buttonText = '立即報名';
    VoidCallback? onPressed;
    Color? buttonColor;
    bool isDestructive = false;

    if (isRegistered) {
      buttonText = '取消報名';
      isDestructive = true;
      buttonColor = theme.colorScheme.error;
      onPressed = () => _showUnregisterDialog(context, event, userId, service, isWaitlist: false);
    } else if (isWaitlisted) {
      buttonText = '退出候補';
      isDestructive = true;
      buttonColor = theme.colorScheme.error;
      onPressed = () => _showUnregisterDialog(context, event, userId, service, isWaitlist: true);
    } else if (event.isFull) {
      buttonText = '加入候補';
      buttonColor = Colors.orange;
      onPressed = () => _showRegisterDialog(context, event, userId, service, isWaitlist: true);
    } else {
      buttonText = '立即報名';
      onPressed = () => _showRegisterDialog(context, event, userId, service, isWaitlist: false);
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
        child: isDestructive
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            )
          : GradientButton(
              text: buttonText,
              onPressed: onPressed,
              // TODO: Support custom color in GradientButton if needed, otherwise it uses primary
            ),
      ),
    );
  }

  void _showRegisterDialog(
    BuildContext context,
    DinnerEventModel event,
    String userId,
    DinnerEventService service,
    {required bool isWaitlist}
  ) {
    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: isWaitlist ? '加入候補名單' : '確認報名',
        content: isWaitlist
            ? '目前活動已滿員，是否要加入候補名單？若有空位將自動遞補。'
            : '確定要報名參加此活動嗎？\n時間：${DateFormat('MM/dd HH:mm').format(event.dateTime)}\n地點：${event.city} ${event.district}',
        confirmText: isWaitlist ? '加入候補' : '確認報名',
        onConfirm: () async {
          try {
             await service.registerForEvent(event.id, userId);
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功！')),
               );
             }
          } catch (e) {
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
               );
             }
          }
        },
      ),
    );
  }

  void _showUnregisterDialog(
    BuildContext context,
    DinnerEventModel event,
    String userId,
    DinnerEventService service,
    {required bool isWaitlist}
  ) {
    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: isWaitlist ? '退出候補' : '取消報名',
        content: isWaitlist
            ? '確定要退出候補名單嗎？'
            : '確定要取消報名嗎？\n注意：活動前 24 小時內不可取消，且頻繁取消可能會影響您的信用評分。',
        confirmText: isWaitlist ? '退出' : '確認取消',
        isDestructive: true,
        onConfirm: () async {
          try {
             await service.unregisterFromEvent(event.id, userId);
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text(isWaitlist ? '已退出候補' : '已取消報名')),
               );
             }
          } catch (e) {
             if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('操作失敗: $e'), backgroundColor: Colors.red),
               );
             }
          }
        },
      ),
    );
  }

  Widget _buildParticipantActions(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
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
