import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/core/theme/app_theme.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/providers/auth_provider.dart';
import 'package:chingu/widgets/empty_state.dart';
import 'package:chingu/core/routes/app_router.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  final NotificationStorageService _storageService = NotificationStorageService();
  final ScrollController _scrollController = ScrollController();

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _storageService.getNotifications(userId: userId);
      if (mounted) {
        setState(() {
          _notifications = result['notifications'];
          _lastDocument = result['lastDocument'];
          _hasMore = result['hasMore'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // 錯誤處理
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _storageService.getNotifications(
        userId: userId,
        lastDocument: _lastDocument,
      );
      if (mounted) {
        setState(() {
          _notifications.addAll(result['notifications']);
          _lastDocument = result['lastDocument'];
          _hasMore = result['hasMore'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthProvider>().uid;
    if (userId == null) return;

    try {
      await _storageService.markAllAsRead(userId);
      if (mounted) {
        setState(() {
          _notifications = _notifications.map((n) => n.markAsRead()).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有通知已標記為已讀')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失敗: $e')),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (!notification.isRead) {
      try {
        await _storageService.markAsRead(notification.id);
        setState(() {
          final index = _notifications.indexWhere((n) => n.id == notification.id);
          if (index != -1) {
            _notifications[index] = notification.markAsRead();
          }
        });
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }

    if (!mounted) return;

    // 根據 actionType 導航
    if (notification.actionType != null) {
      switch (notification.actionType) {
        case 'open_chat':
          // 如果是打開聊天，通常需要 chatRoomId 或 userId
          // 這裡假設 actionData 存的是 chatRoomId 或者是 json
          // 為了簡化，如果 actionType 是 open_chat，我們跳轉到聊天列表
          Navigator.pushNamed(context, AppRoutes.chatList);
          break;
        case 'view_event':
           // 如果有 eventId (在 actionData 中)
           if (notification.actionData != null) {
             Navigator.pushNamed(
               context,
               AppRoutes.eventDetail,
               arguments: notification.actionData, // 假設 actionData 是 eventId
             );
           } else {
             Navigator.pushNamed(context, AppRoutes.eventsList);
           }
          break;
        case 'match_history':
          Navigator.pushNamed(context, AppRoutes.matchesList);
          break;
        default:
          // 預設行為
          break;
      }
    } else {
      // 根據 type 的 fallback 導航
      switch (notification.type) {
        case 'match':
          Navigator.pushNamed(context, AppRoutes.matchesList);
          break;
        case 'event':
           Navigator.pushNamed(context, AppRoutes.eventsList);
           break;
        case 'message':
           Navigator.pushNamed(context, AppRoutes.chatList);
           break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chinguTheme = theme.extension<ChinguTheme>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '通知中心',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
          color: theme.colorScheme.onSurface,
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                '全部已讀',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.notifications_off_outlined,
                  title: '沒有新通知',
                  message: '您目前沒有任何通知消息',
                  useGradientBackground: true,
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _notifications.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final notification = _notifications[index];
                      return _buildNotificationItem(
                        context,
                        notification,
                        theme,
                        chinguTheme,
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    NotificationModel notification,
    ThemeData theme,
    ChinguTheme? chinguTheme,
  ) {
    // 根據類型決定圖標和顏色
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'match':
        icon = Icons.favorite_rounded;
        color = theme.colorScheme.error;
        break;
      case 'message':
        icon = Icons.chat_bubble_rounded;
        color = theme.colorScheme.primary;
        break;
      case 'event':
        icon = Icons.event_available_rounded;
        color = chinguTheme?.success ?? Colors.green;
        break;
      case 'rating':
        icon = Icons.stars_rounded;
        color = chinguTheme?.warning ?? Colors.amber;
        break;
      case 'system':
      default:
        icon = Icons.notifications_rounded;
        color = theme.colorScheme.primary;
    }

    // 格式化時間
    final diff = DateTime.now().difference(notification.createdAt);
    String timeStr;
    if (diff.inHours < 24) {
      timeStr = '${diff.inHours} 小時前';
      if (diff.inHours == 0) timeStr = '${diff.inMinutes} 分鐘前';
    } else {
      timeStr = '${diff.inDays} 天前';
      if (diff.inDays == 1) timeStr = '昨天';
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        // 先從 UI 移除
        setState(() {
          _notifications.removeAt(_notifications.indexOf(notification));
        });
        // 再從後端移除
        try {
          await _storageService.deleteNotification(notification.id);
        } catch (e) {
          // 失敗處理...
        }
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          color: !notification.isRead
              ? theme.colorScheme.primary.withOpacity(0.05)
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.2),
                      color.withOpacity(0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: !notification.isRead
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 8, left: 8),
                  decoration: BoxDecoration(
                    gradient: chinguTheme?.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
