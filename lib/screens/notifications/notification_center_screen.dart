import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_router.dart';
import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_storage_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/shimmer_widget.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  final NotificationStorageService _storageService = NotificationStorageService();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = false;
  String _currentFilter = 'all'; // 'all', 'match', 'event', 'system'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      String newFilter;
      switch (_tabController.index) {
        case 1:
          newFilter = 'match';
          break;
        case 2:
          newFilter = 'event';
          break;
        case 3:
          newFilter = 'system';
          break;
        case 0:
        default:
          newFilter = 'all';
          break;
      }

      setState(() {
        _currentFilter = newFilter;
        _notifications = [];
        _lastDocument = null;
        _hasMore = false;
        _isLoading = true;
      });
      _loadNotifications();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    try {
      final result = await _storageService.getNotifications(
        userId,
        limit: 20,
        lastDocument: null,
        type: _currentFilter == 'all' ? null : _currentFilter,
      );

      if (mounted) {
        setState(() {
          _notifications = result['notifications'] as List<NotificationModel>;
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore) return;

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final result = await _storageService.getNotifications(
        userId,
        limit: 20,
        lastDocument: _lastDocument,
        type: _currentFilter == 'all' ? null : _currentFilter,
      );

      if (mounted) {
        setState(() {
          _notifications.addAll(result['notifications'] as List<NotificationModel>);
          _lastDocument = result['lastDocument'] as DocumentSnapshot?;
          _hasMore = result['hasMore'] as bool;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading more notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    try {
      await _storageService.markAllAsRead(userId);
      setState(() {
        _notifications = _notifications.map((n) => n.markAsRead()).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('標記已讀失敗: $e')),
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

    final navigator = Navigator.of(context);

    // Use actionType first
    final actionType = notification.actionType;
    // final actionData = notification.actionData; // unused currently

    if (actionType != null) {
        if (actionType == 'open_chat') {
           navigator.pushNamed(AppRoutes.chatList);
        } else if (actionType == 'view_event') {
           navigator.pushNamed(AppRoutes.eventDetail); // Note: Should pass args if ID exists
        } else if (actionType == 'match_history') {
           navigator.pushNamed(AppRoutes.matchesList);
        }
    } else {
        // Fallback based on type
        if (notification.type == 'match') {
             navigator.pushNamed(AppRoutes.matchesList);
        } else if (notification.type == 'message') {
             navigator.pushNamed(AppRoutes.chatList);
        } else if (notification.type == 'event') {
             navigator.pushNamed(AppRoutes.eventsList);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          icon: Icon(Icons.arrow_back_ios_new, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: theme.colorScheme.primary),
            tooltip: '全部已讀',
            onPressed: _notifications.any((n) => !n.isRead) ? _markAllAsRead : null,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '配對'),
            Tab(text: '活動'),
            Tab(text: '系統'),
          ],
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 8,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) => const _SkeletonNotificationTile(),
      );
    }

    if (_notifications.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.notifications_off_outlined,
        title: '暫無通知',
        message: '您目前沒有${_getFilterName()}相關的通知消息',
        useGradientBackground: true,
        actionLabel: '重新整理',
        onActionPressed: () {
            setState(() {
                _isLoading = true;
                _notifications = [];
                _lastDocument = null;
            });
            _loadNotifications();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
            _isLoading = true;
            _notifications = [];
            _lastDocument = null;
        });
        await _loadNotifications();
      },
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
          return _NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  String _getFilterName() {
    switch (_currentFilter) {
      case 'match': return '配對';
      case 'event': return '活動';
      case 'system': return '系統';
      default: return '';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon and color based on type
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'match':
        iconData = Icons.favorite_rounded;
        iconColor = Colors.pink;
        break;
      case 'event':
        iconData = Icons.calendar_today_rounded;
        iconColor = Colors.orange;
        break;
      case 'message':
        iconData = Icons.chat_bubble_rounded;
        iconColor = Colors.blue;
        break;
      case 'rating':
        iconData = Icons.star_rounded;
        iconColor = Colors.amber;
        break;
      case 'system':
      default:
        iconData = Icons.notifications_rounded;
        iconColor = theme.colorScheme.primary;
        break;
    }

    return Material(
      color: notification.isRead
          ? theme.scaffoldBackgroundColor
          : theme.colorScheme.primary.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon or Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: notification.imageUrl != null
                    ? ClipOval(
                        child: Image.network(
                          notification.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(iconData, color: iconColor),
                        ),
                      )
                    : Icon(iconData, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '剛剛';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分鐘前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小時前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${time.month}/${time.day}';
    }
  }
}

class _SkeletonNotificationTile extends StatelessWidget {
  const _SkeletonNotificationTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerWidget.circular(width: 48, height: 48),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerWidget.rectangular(width: 150, height: 16),
                const SizedBox(height: 8),
                const ShimmerWidget.rectangular(width: double.infinity, height: 14),
                const SizedBox(height: 4),
                const ShimmerWidget.rectangular(width: 200, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
