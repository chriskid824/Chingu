import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/loading_dialog.dart';
import 'package:chingu/utils/haptic_utils.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final eventId = args?['eventId'] as String?;

    if (eventId == null) {
      return Scaffold(
        body: Center(child: Text('Error: No event ID provided')),
      );
    }

    final dinnerProvider = Provider.of<DinnerEventProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.uid;

    return StreamBuilder<DinnerEventModel?>(
      stream: dinnerProvider.getEventStream(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Event not found')),
          );
        }

        final event = snapshot.data!;
        final isParticipant = currentUserId != null && event.participantIds.contains(currentUserId);
        final isWaiting = currentUserId != null && event.waitingListIds.contains(currentUserId);
        final isFull = event.participantIds.length >= event.maxParticipants;
        final isClosed = event.isRegistrationClosed;

        String statusText;
        Color statusColor;

        if (event.status == 'cancelled') {
          statusText = '已取消';
          statusColor = theme.colorScheme.error;
        } else if (event.status == 'completed') {
          statusText = '已完成';
          statusColor = theme.colorScheme.secondary;
        } else if (isParticipant) {
          statusText = '已報名';
          statusColor = chinguTheme?.success ?? Colors.green;
        } else if (isWaiting) {
          statusText = '候補中 (第${event.waitingListIds.indexOf(currentUserId!) + 1}位)';
          statusColor = chinguTheme?.warning ?? Colors.orange;
        } else if (isClosed) {
          statusText = '報名已截止';
          statusColor = theme.disabledColor;
        } else if (isFull) {
          statusText = '已額滿 (可候補)';
          statusColor = chinguTheme?.warning ?? Colors.orange;
        } else {
          statusText = '開放報名中';
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
                      // TODO: Share logic
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
                              border: Border.all(color: statusColor.withOpacity(0.5)),
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
                        '${event.city} ${event.district}\n${event.restaurantName ?? '餐廳配對中...'}',
                        chinguTheme?.success ?? Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        context,
                        Icons.people_rounded,
                        '參加人數',
                        '${event.maxParticipants} 人（固定）\n目前已報名：${event.participantIds.length} 人${event.waitingListIds.isNotEmpty ? ' (候補 ${event.waitingListIds.length} 人)' : ''}',
                        chinguTheme?.warning ?? Colors.orange,
                      ),

                      if (event.notes != null && event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          context,
                          Icons.note_alt_rounded,
                          '備註',
                          event.notes!,
                          Colors.grey,
                        ),
                      ],

                      // Only show actions if user is joined
                      if (isParticipant) ...[
                         const SizedBox(height: 32),
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
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomAction(
            context,
            event,
            isParticipant,
            isWaiting,
            isFull,
            isClosed,
            currentUserId,
          ),
        );
      },
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    DinnerEventModel event,
    bool isParticipant,
    bool isWaiting,
    bool isFull,
    bool isClosed,
    String? currentUserId,
  ) {
    if (currentUserId == null) return const SizedBox.shrink();
    if (event.status == 'cancelled' || event.status == 'completed') return const SizedBox.shrink();

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    String buttonText;
    VoidCallback? onPressed;
    bool isDestructive = false;

    if (isParticipant) {
      buttonText = '取消報名';
      isDestructive = true;
      onPressed = () => _showLeaveDialog(context, event.id, currentUserId, false);
    } else if (isWaiting) {
      buttonText = '取消候補';
      isDestructive = true;
      onPressed = () => _showLeaveDialog(context, event.id, currentUserId, true);
    } else if (isClosed) {
      buttonText = '報名已截止';
      onPressed = null; // Disabled
    } else if (isFull) {
      buttonText = '加入候補名單';
      onPressed = () => _showJoinDialog(context, event.id, currentUserId, true);
    } else {
      buttonText = '立即報名';
      onPressed = () => _showJoinDialog(context, event.id, currentUserId, false);
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
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: theme.colorScheme.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              )
            : GradientButton(
                text: buttonText,
                onPressed: onPressed,
                gradient: onPressed == null ? LinearGradient(colors: [Colors.grey, Colors.grey]) : null,
              ),
      ),
    );
  }

  void _showJoinDialog(BuildContext context, String eventId, String userId, bool isWaitlist) {
    HapticUtils.selection();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入候補？' : '確認報名？'),
        content: Text(isWaitlist
            ? '目前活動已額滿。如果有參與者退出，您將依序自動遞補並收到通知。'
            : '報名後請務必準時出席。無故缺席可能會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _performJoin(context, eventId, userId);
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  Future<void> _performJoin(BuildContext context, String eventId, String userId) async {
    final provider = Provider.of<DinnerEventProvider>(context, listen: false);

    // Show loading
    LoadingDialog.show(context);

    try {
      final success = await provider.joinEvent(eventId, userId);
      LoadingDialog.hide(context);

      if (success) {
        HapticUtils.success();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('報名成功！')),
          );
        }
      } else {
        HapticUtils.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? '報名失敗')),
          );
        }
      }
    } catch (e) {
      LoadingDialog.hide(context);
      HapticUtils.error();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e')),
        );
      }
    }
  }

  void _showLeaveDialog(BuildContext context, String eventId, String userId, bool isWaitlist) {
    HapticUtils.selection();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '取消候補？' : '取消報名？'),
        content: Text(isWaitlist
            ? '您確定要從候補名單中移除嗎？'
            : '確定要取消報名嗎？如果在活動開始前4小時內取消，可能會被扣除信用點數。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLeave(context, eventId, userId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLeave(BuildContext context, String eventId, String userId) async {
    final provider = Provider.of<DinnerEventProvider>(context, listen: false);
    LoadingDialog.show(context);

    try {
      final success = await provider.leaveEvent(eventId, userId);
      LoadingDialog.hide(context);

      if (success) {
        HapticUtils.success();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消報名')),
          );
        }
      } else {
        HapticUtils.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.errorMessage ?? '取消失敗')),
          );
        }
      }
    } catch (e) {
      LoadingDialog.hide(context);
      HapticUtils.error();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發生錯誤: $e')),
        );
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
