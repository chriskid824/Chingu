import 'package:flutter/material.dart';
import 'package:chingu/models/notification_model.dart';

class NotificationStatsProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  // Stats
  int _totalNotifications = 0;
  int _unreadCount = 0;
  int _readCount = 0;
  double _engagementRate = 0.0;
  Map<String, int> _typeDistribution = {};

  // Getters
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get totalNotifications => _totalNotifications;
  int get unreadCount => _unreadCount;
  int get readCount => _readCount;
  double get engagementRate => _engagementRate;
  Map<String, int> get typeDistribution => _typeDistribution;

  NotificationStatsProvider() {
    _loadMockData(); // Initialize with mock data
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Simulating delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final now = DateTime.now();
      _notifications = [
        NotificationModel(
          id: '1',
          userId: 'user1',
          type: 'match',
          title: '喜歡',
          message: '王小華 喜歡了您的個人資料',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        NotificationModel(
          id: '2',
          userId: 'user1',
          type: 'message',
          title: '訊息',
          message: '李小美 傳送了一則訊息給您',
          isRead: false,
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        NotificationModel(
          id: '3',
          userId: 'user1',
          type: 'event',
          title: '活動',
          message: '您與 陳大明 的晚餐預約已確認',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 1)),
        ),
        NotificationModel(
          id: '4',
          userId: 'user1',
          type: 'rating',
          title: '成就',
          message: '恭喜！您獲得了新的成就徽章',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        NotificationModel(
          id: '5',
          userId: 'user1',
          type: 'match',
          title: '配對',
          message: '林小芳 想要與您配對',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        NotificationModel(
          id: '6',
          userId: 'user1',
          type: 'event',
          title: '提醒',
          message: '本週三晚餐報名即將截止',
          isRead: true,
          createdAt: now.subtract(const Duration(days: 4)),
        ),
      ];
      _calculateStats();
      _isLoading = false;
      notifyListeners();
    });
  }

  void _calculateStats() {
    _totalNotifications = _notifications.length;
    if (_totalNotifications == 0) {
      _unreadCount = 0;
      _readCount = 0;
      _engagementRate = 0.0;
      _typeDistribution = {};
      return;
    }

    _unreadCount = _notifications.where((n) => !n.isRead).length;
    _readCount = _notifications.where((n) => n.isRead).length;
    _engagementRate = _readCount / _totalNotifications;

    _typeDistribution = {};
    for (var n in _notifications) {
      _typeDistribution[n.type] = (_typeDistribution[n.type] ?? 0) + 1;
    }
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].markAsRead();
      _calculateStats();
      notifyListeners();
    }
  }

  void markAllAsRead() {
    _notifications = _notifications.map((n) => n.markAsRead()).toList();
    _calculateStats();
    notifyListeners();
  }

  void trackEngagement(String notificationId) {
    // Logic to track engagement (e.g. click, interact)
    // For now we just mark as read if it wasn't
    markAsRead(notificationId);
    debugPrint('Engagement tracked for notification: $notificationId');
  }
}
