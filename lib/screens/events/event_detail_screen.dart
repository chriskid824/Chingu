import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/widgets/gradient_button.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/providers/dinner_event_provider.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final DinnerEventService _eventService = DinnerEventService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DinnerEventModel?>(
      stream: _eventService.getEventStream(widget.eventId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('發生錯誤: ${snapshot.error}')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final event = snapshot.data;
        if (event == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('找不到活動')),
          );
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(context, event),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, event),
                      const SizedBox(height: 24),
                      _buildInfoSection(context, event),
                      const SizedBox(height: 32),
                      _buildActionButtons(context, event),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, event, userId),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);

    // 根據預算或地點顯示不同圖片（這裡暫時隨機或固定）
    final imageUrl = 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80';

    return SliverAppBar(
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
            // TODO: Share event
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
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
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.city,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    Color statusColor;
    String statusText;

    switch (event.status) {
      case EventStatus.confirmed:
        statusColor = chinguTheme?.success ?? Colors.green;
        statusText = '已成團';
        break;
      case EventStatus.pending:
        statusColor = chinguTheme?.warning ?? Colors.orange;
        statusText = '等待中';
        break;
      case EventStatus.completed:
        statusColor = theme.disabledColor;
        statusText = '已結束';
        break;
      case EventStatus.cancelled:
        statusColor = theme.colorScheme.error;
        statusText = '已取消';
        break;
    }

    // 如果人數已滿但還是 pending (理論上 Service 會轉 confirmed，但以防萬一)
    if (event.status == EventStatus.pending && event.isFull) {
       statusColor = chinguTheme?.success ?? Colors.green;
       statusText = '已額滿';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            '${event.city}${event.district}晚餐',
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
                Icons.circle,
                size: 10,
                color: statusColor,
              ),
              const SizedBox(width: 6),
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
    );
  }

  Widget _buildInfoSection(BuildContext context, DinnerEventModel event) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    final dateFormat = DateFormat('yyyy年MM月dd日 (E)\nHH:mm', 'zh_TW');
    final dateStr = dateFormat.format(event.dateTime);

    return Column(
      children: [
        _buildInfoCard(
          context,
          Icons.calendar_today_rounded,
          '日期時間',
          dateStr,
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
          '${event.city}${event.district}', // 具體餐廳在成團後顯示，這裡只顯示大概
          chinguTheme?.success ?? Colors.green,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          context,
          Icons.people_rounded,
          '參加人數',
          '上限 6 人\n目前已報名：${event.participantIds.length} 人${event.waitingListIds.isNotEmpty ? " (候補 ${event.waitingListIds.length} 人)" : ""}',
          chinguTheme?.warning ?? Colors.orange,
        ),
        if (event.registrationDeadline != null) ...[
          const SizedBox(height: 12),
          _buildInfoCard(
            context,
            Icons.timer_rounded,
            '報名截止',
            DateFormat('MM月dd日 HH:mm', 'zh_TW').format(event.registrationDeadline!),
            Colors.redAccent,
          ),
        ],
        if (event.notes != null && event.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '備註',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  event.notes!,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ]
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

  Widget _buildActionButtons(BuildContext context, DinnerEventModel event) {
    // 只有已確認參加的用戶才顯示聊天和導航按鈕
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isConfirmed = event.isUserConfirmed(authProvider.uid!);

    if (!isConfirmed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // TODO: Navigate to Chat
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
              onPressed: () {
                // TODO: Navigate to Maps
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
    );
  }

  Widget _buildBottomBar(BuildContext context, DinnerEventModel event, String userId) {
    final theme = Theme.of(context);
    final eventProvider = Provider.of<DinnerEventProvider>(context);

    final isJoined = event.participantIds.contains(userId);
    final isWaitlisted = event.waitingListIds.contains(userId);
    final isFull = event.isFull;
    final isDeadlinePassed = event.registrationDeadline != null &&
                             DateTime.now().isAfter(event.registrationDeadline!);
    final isCancelled = event.status == EventStatus.cancelled;
    final isCompleted = event.status == EventStatus.completed;

    Widget button;

    if (isCompleted) {
      button = const GradientButton(
        text: '活動已結束',
        onPressed: null,
      );
    } else if (isCancelled) {
      button = const GradientButton(
        text: '活動已取消',
        onPressed: null,
      );
    } else if (isJoined) {
       button = OutlinedButton(
        onPressed: eventProvider.isLoading ? null : () => _showCancelDialog(context, event, userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: theme.colorScheme.error),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: eventProvider.isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
          : Text(
            '取消報名',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.error,
            ),
          ),
      );
    } else if (isWaitlisted) {
      button = OutlinedButton(
        onPressed: eventProvider.isLoading ? null : () => _showCancelDialog(context, event, userId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: eventProvider.isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator())
          : const Text(
            '取消候補',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.orange,
            ),
          ),
      );
    } else {
      // Not joined
      if (isDeadlinePassed) {
        button = const GradientButton(
          text: '報名已截止',
          onPressed: null,
        );
      } else if (isFull) {
         button = GradientButton(
          text: '加入候補名單',
          colors: const [Colors.orange, Colors.deepOrange],
          onPressed: eventProvider.isLoading ? null : () => _showJoinDialog(context, event, userId, true),
        );
      } else {
        button = GradientButton(
          text: '立即報名',
          onPressed: eventProvider.isLoading ? null : () => _showJoinDialog(context, event, userId, false),
        );
      }
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
        child: button,
      ),
    );
  }

  void _showJoinDialog(BuildContext context, DinnerEventModel event, String userId, bool isWaitlist) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isWaitlist ? '加入候補名單' : '確認報名'),
        content: Text(isWaitlist
          ? '目前活動人數已滿，您確定要加入候補名單嗎？\n如果有參與者退出，您將有機會遞補。'
          : '您確定要報名參加此晚餐活動嗎？\n\n時間：${DateFormat('MM/dd HH:mm').format(event.dateTime)}\n地點：${event.city}${event.district}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final provider = Provider.of<DinnerEventProvider>(context, listen: false);
              final success = await provider.joinEvent(event.id, userId);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isWaitlist ? '已加入候補名單' : '報名成功！')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: ${provider.errorMessage}')),
                  );
                }
              }
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, DinnerEventModel event, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('取消確認'),
        content: const Text('您確定要取消嗎？\n如果是已確認的活動，頻繁取消可能會影響您的信用評分。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('保留'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final provider = Provider.of<DinnerEventProvider>(context, listen: false);
              final success = await provider.leaveEvent(event.id, userId);

              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已取消')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('操作失敗: ${provider.errorMessage}')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('確認取消'),
          ),
        ],
      ),
    );
  }
}
