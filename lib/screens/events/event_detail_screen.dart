import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/event_registration_status.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/widgets/event_registration_dialog.dart';

class EventDetailScreen extends StatelessWidget {
  const EventDetailScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    // Get event from arguments
    final event = ModalRoute.of(context)?.settings.arguments as DinnerEventModel?;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('活動詳情')),
        body: const Center(child: Text('找不到活動資料')),
      );
    }

    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');

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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: chinguTheme?.successGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.info_outline,
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
                    dateFormat.format(event.dateTime),
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
                    '${event.confirmedCount} / ${event.maxParticipants} 人\n候補人數：${event.waitingList.length}',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  if (event.notes != null && event.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('備註', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(event.notes!),
                  ],

                  // Action Buttons (Chat/Navigate) only if confirmed
                  if (event.status == 'confirmed' || event.status == 'completed') ...[
                     const SizedBox(height: 32),
                     _buildActionButtons(context, theme, chinguTheme),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, event, theme),
    );
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, ThemeData theme) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.userModel;
        if (user == null) return const SizedBox.shrink();

        final isRegistered = event.isUserRegistered(user.uid);
        final isOnWaitlist = event.isUserOnWaitlist(user.uid);
        final isFull = event.isFull;
        final isCreator = event.creatorId == user.uid;

        // Check if event is past
        if (event.dateTime.isBefore(DateTime.now())) {
           return Container(
            padding: const EdgeInsets.all(24),
            color: theme.cardColor,
            child: const Text('活動已結束', textAlign: TextAlign.center),
          );
        }

        String buttonText = '立即報名';
        VoidCallback? onPressed;
        Color? buttonColor;

        if (isRegistered) {
          buttonText = '取消報名';
          buttonColor = theme.colorScheme.error;
          onPressed = () => _showCancelDialog(context, event, user.uid);
        } else if (isOnWaitlist) {
          buttonText = '取消候補'; // Allows leaving waitlist
          buttonColor = theme.colorScheme.error; // Or warning color
          onPressed = () => _showCancelDialog(context, event, user.uid);
        } else if (isFull) {
          buttonText = '加入候補名單';
          onPressed = () => _showWaitlistDialog(context, event, user.uid);
        } else {
          buttonText = '立即報名';
          onPressed = () => _showRegisterDialog(context, event, user.uid);
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
            child: Consumer<DinnerEventProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return GradientButton(
                  text: buttonText,
                  onPressed: onPressed,
                  colors: buttonColor != null ? [buttonColor, buttonColor] : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showRegisterDialog(BuildContext context, DinnerEventModel event, String userId) {
    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: '確認報名',
        message: '確定要報名此活動嗎？\n時間：${DateFormat('MM/dd HH:mm').format(event.dateTime)}',
        confirmText: '確認報名',
        onConfirm: () async {
          final success = await context.read<DinnerEventProvider>().registerForEvent(event.id, userId);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('報名成功！')),
            );
            Navigator.of(context).pop(); // Go back to list or stay? Usually stay to see status change.
            // Actually pop logic in dialog handles closing dialog.
            // We might want to refresh the page or pop the screen.
          } else if (context.mounted) {
             final error = context.read<DinnerEventProvider>().errorMessage;
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? '報名失敗')),
            );
          }
        },
      ),
    );
  }

  void _showWaitlistDialog(BuildContext context, DinnerEventModel event, String userId) {
    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: '加入候補',
        message: '目前活動已滿額。確定要加入候補名單嗎？\n如果有空位釋出，將會自動遞補。',
        confirmText: '加入候補',
        onConfirm: () async {
          final success = await context.read<DinnerEventProvider>().registerForEvent(event.id, userId);
           if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已加入候補名單！')),
            );
          } else if (context.mounted) {
             final error = context.read<DinnerEventProvider>().errorMessage;
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? '加入失敗')),
            );
          }
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context, DinnerEventModel event, String userId) {
    showDialog(
      context: context,
      builder: (context) => EventRegistrationDialog(
        title: '取消報名',
        message: '確定要取消報名嗎？\n活動開始前24小時內不可取消。',
        confirmText: '確認取消',
        isDestructive: true,
        onConfirm: () async {
          final success = await context.read<DinnerEventProvider>().unregisterFromEvent(event.id, userId);
           if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已取消報名')),
            );
            Navigator.of(context).pop(); // Exit screen on cancel? Or just update UI.
          } else if (context.mounted) {
             final error = context.read<DinnerEventProvider>().errorMessage;
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error ?? '取消失敗')),
            );
          }
        },
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

  Widget _buildActionButtons(BuildContext context, ThemeData theme, ChinguTheme? chinguTheme) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {}, // TODO: Navigate to Chat
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
                onPressed: () {}, // TODO: Navigate to Navigation
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
}
