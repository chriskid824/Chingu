import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';
import 'package:chingu/widgets/loading_dialog.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Get eventId from arguments
    final eventId = ModalRoute.of(context)?.settings.arguments as String?;

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('無效的活動 ID')),
      );
    }

    final userId = context.watch<AuthProvider>().user?.uid;

    return StreamBuilder<DinnerEventModel?>(
      stream: context.read<DinnerEventProvider>().getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('活動不存在')));
        }

        final event = snapshot.data!;

        // Determine status
        bool isParticipant = userId != null && event.participantIds.contains(userId);
        bool isWaitlisted = userId != null && event.waitingListIds.contains(userId);
        bool isFull = event.isFull;
        bool isPast = event.dateTime.isBefore(DateTime.now());

        String statusText;
        Color statusColor;

        if (event.status == 'cancelled') {
           statusText = '已取消';
           statusColor = Colors.grey;
        } else if (isParticipant) {
           statusText = '已報名';
           statusColor = Colors.green;
        } else if (isWaitlisted) {
           statusText = '候補中 (${event.waitingListIds.indexOf(userId!) + 1})';
           statusColor = Colors.orange;
        } else if (isFull) {
           statusText = '已滿員';
           statusColor = Colors.red;
        } else {
           statusText = '可報名';
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
                      // Placeholder or restaurant image if available
                      Container(color: Colors.grey.shade300),
                      Image.network(
                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
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
                             const Icon(Icons.restaurant, size: 80, color: Colors.white),
                             const SizedBox(height: 12),
                             Text(
                                event.city,
                                style: const TextStyle(fontSize: 30, color: Colors.white, fontWeight: FontWeight.bold),
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
                              '6人晚餐聚會', // Dynamic title?
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
                        '${event.dateTime.year}/${event.dateTime.month}/${event.dateTime.day} ${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
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
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.currentParticipants} / ${event.maxParticipants} 人\n候補人數: ${event.waitingListIds.length}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      const SizedBox(height: 32),

                      if (isParticipant)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {}, // Navigate to chat
                              icon: const Icon(Icons.chat_bubble_rounded),
                              label: const Text('聊天'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          // Add Navigation button etc if needed
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isPast ? Container(
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
              child: _buildActionButton(context, event, userId, isParticipant, isWaitlisted, isFull),
            ),
          ) : null,
        );
      }
    );
  }
  
  Widget _buildActionButton(BuildContext context, DinnerEventModel event, String? userId, bool isParticipant, bool isWaitlisted, bool isFull) {
    if (userId == null) return const SizedBox();

    if (isParticipant || isWaitlisted) {
      return OutlinedButton(
        onPressed: () => _handleUnregister(context, event, userId, isParticipant),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(isParticipant ? '取消報名' : '取消候補', style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    } else {
      return GradientButton(
        text: isFull ? '加入候補' : '立即報名',
        onPressed: () => _handleRegister(context, event, userId, isFull),
      );
    }
  }

  Future<void> _handleRegister(BuildContext context, DinnerEventModel event, String userId, bool isFull) async {
     final confirm = await EventRegistrationDialog.show(
       context,
       title: isFull ? '加入候補名單' : '確認報名',
       content: isFull
         ? '目前活動已滿，是否加入候補名單？若有名額將自動遞補。'
         : '確定要報名此活動嗎？\n時間：${event.dateTime}',
       confirmText: isFull ? '加入候補' : '確認報名',
       onConfirm: () {},
     );

     if (confirm == true) {
       LoadingDialog.show(context, message: '處理中...');
       try {
         final success = await context.read<DinnerEventProvider>().registerForEvent(event.id, userId);
         LoadingDialog.hide(context);
         if (!success) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<DinnerEventProvider>().errorMessage ?? '失敗')));
         } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報名成功')));
         }
       } catch (e) {
         LoadingDialog.hide(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e')));
       }
     }
  }

  Future<void> _handleUnregister(BuildContext context, DinnerEventModel event, String userId, bool isParticipant) async {
     final confirm = await EventRegistrationDialog.show(
       context,
       title: '取消',
       content: isParticipant
         ? '確定要取消報名嗎？\n活動前24小時內不可取消。'
         : '確定要退出候補名單嗎？',
       confirmText: '確認取消',
       isDestructive: true,
       onConfirm: () {},
     );

     if (confirm == true) {
       LoadingDialog.show(context, message: '處理中...');
       try {
         final success = await context.read<DinnerEventProvider>().unregisterFromEvent(event.id, userId);
         LoadingDialog.hide(context);
         if (!success) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<DinnerEventProvider>().errorMessage ?? '失敗')));
         } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消')));
         }
       } catch (e) {
         LoadingDialog.hide(context);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('錯誤: $e')));
       }
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
