import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isLoading = true;
  final DinnerEventService _eventService = DinnerEventService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      try {
        final event = await _eventService.getEvent(args);
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
            SnackBar(content: Text('載入失敗: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleRegistration() async {
    if (_event == null) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    final status = _event!.getUserRegistrationStatus(user.uid);

    if (status == EventRegistrationStatus.none) {
      // Register logic
      final confirmed = await EventRegistrationDialog.show(
        context: context,
        title: '確認報名',
        content: _event!.isFull
            ? '活動已滿員，是否加入候補名單？\n若有參加者取消，將依序遞補通知。'
            : '確定要報名此活動嗎？\n請確保您能準時出席。',
        confirmText: _event!.isFull ? '加入候補' : '確認報名',
        onConfirm: () async {
          try {
             final result = await _eventService.registerForEvent(_event!.id, user.uid);
             String message = result == EventRegistrationStatus.registered
                 ? '報名成功！'
                 : '已加入候補名單';

             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                _loadEvent(); // Reload
             }
          } catch (e) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
             }
          }
        },
      );
    } else {
      // Cancel logic
      final confirmed = await EventRegistrationDialog.show(
        context: context,
        title: '取消報名',
        content: status == EventRegistrationStatus.waitlist
            ? '確定要從候補名單中移除嗎？'
            : '確定要取消報名嗎？\n活動前24小時內取消可能會影響您的信用評分。',
        confirmText: '確認取消',
        isDestructive: true,
        onConfirm: () async {
          try {
             await _eventService.unregisterFromEvent(_event!.id, user.uid);
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已取消報名')));
                _loadEvent(); // Reload
             }
          } catch (e) {
             if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗: $e')));
             }
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final user = Provider.of<AuthProvider>(context).userModel;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到活動')),
      );
    }

    final event = _event!;
    final userStatus = user != null ? event.getUserRegistrationStatus(user.uid) : EventRegistrationStatus.none;

    String statusText;
    Color statusColor;

    if (event.status == 'cancelled') {
       statusText = '活動已取消';
       statusColor = Colors.red;
    } else if (userStatus == EventRegistrationStatus.registered) {
       statusText = '已報名';
       statusColor = Colors.green;
    } else if (userStatus == EventRegistrationStatus.waitlist) {
       statusText = '候補中 (第${event.waitlist.indexOf(user!.uid) + 1}位)';
       statusColor = Colors.orange;
    } else if (event.isFull) {
       statusText = '已額滿 (可候補)';
       statusColor = Colors.orange;
    } else {
       statusText = '報名中';
       statusColor = Colors.blue;
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
                          border: Border.all(color: statusColor),
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
                    '${event.city} ${event.district}\n${event.restaurantName ?? "餐廳待定"}',
                    chinguTheme?.success ?? Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    context,
                    Icons.people_rounded,
                    '參加人數',
                    '上限 ${event.maxParticipants} 人\n目前已報名：${event.currentParticipants} 人\n候補人數：${event.waitlistCount} 人',
                    chinguTheme?.warning ?? Colors.orange,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons (Chat/Navigation) - only if registered
                  if (userStatus == EventRegistrationStatus.registered) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                               // Open chat
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
                        const SizedBox(width: 12),
                        // Only show Navigation if restaurant is set
                        if (event.restaurantLocation != null)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: chinguTheme?.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                 // Navigation
                              },
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
          child: _buildActionButton(userStatus, event, chinguTheme),
        ),
      ),
    );
  }

  Widget _buildActionButton(EventRegistrationStatus userStatus, DinnerEventModel event, ChinguTheme? chinguTheme) {
    if (event.status == 'cancelled' || event.status == 'completed') {
      return GradientButton(
        text: event.status == 'cancelled' ? '活動已取消' : '活動已結束',
        onPressed: () {},
        colors: [Colors.grey, Colors.grey],
      );
    }

    // Check deadline for cancellation
    if (userStatus == EventRegistrationStatus.registered && !event.canCancel) {
       return GradientButton(
        text: '已過取消期限',
        onPressed: () {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('活動前24小時內不可取消，請聯繫客服或自行負責。'))
           );
        },
        colors: [Colors.grey, Colors.grey],
      );
    }

    String text;
    List<Color>? colors;

    if (userStatus == EventRegistrationStatus.registered) {
      text = '取消報名';
      colors = [Colors.redAccent, Colors.red];
    } else if (userStatus == EventRegistrationStatus.waitlist) {
      text = '取消候補';
      colors = [Colors.orangeAccent, Colors.orange];
    } else if (event.isFull) {
      text = '加入候補名單';
      colors = [Colors.orange, Colors.deepOrange];
    } else {
      text = '立即報名';
      colors = null; // Use default primary gradient
    }

    return GradientButton(
      text: text,
      onPressed: _handleRegistration,
      colors: colors,
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
