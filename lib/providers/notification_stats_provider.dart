import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/providers/auth_provider.dart';

class NotificationStatsProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  AuthProvider? _authProvider; // Can be null initially
  StreamSubscription<int>? _unreadCountSubscription;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  int _unreadCount = 0;
  String? _currentUserId;

  NotificationStatsProvider(this._authProvider) {
    _init();
  }

  void updateAuth(AuthProvider auth) {
    if (_authProvider != auth || _currentUserId != auth.user?.uid) {
      _authProvider = auth;
      _init();
    }
  }

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    super.dispose();
  }

  void _init() {
    final newUserId = _authProvider?.user?.uid;

    // Check if user actually changed
    if (newUserId == _currentUserId) return;

    _currentUserId = newUserId;

    // Cancel existing subscription
    _unreadCountSubscription?.cancel();
    _unreadCountSubscription = null;

    if (newUserId != null) {
      _listenToUnreadCount();
      // Reset and load notifications
      loadNotifications(refresh: true);
    } else {
       // Reset if logged out
       _notifications = [];
       _unreadCount = 0;
       _lastDocument = null;
       _hasMore = true;
       notifyListeners();
    }
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get unreadCount => _unreadCount;

  // Listen to unread count stream
  void _listenToUnreadCount() {
    final userId = _currentUserId;
    if (userId == null) return;

    _unreadCountSubscription = _notificationService.streamUnreadCount(userId).listen((count) {
      _unreadCount = count;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to unread count: $e');
    });
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    final userId = _currentUserId;
    if (userId == null) return;
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      if (refresh) {
        _lastDocument = null;
        // Don't clear notifications immediately to avoid UI flicker, unless necessary
        // _notifications = [];
      }

      final result = await _notificationService.fetchNotifications(
        userId: userId,
        lastDocument: _lastDocument,
      );

      final newNotifications = result['notifications'] as List<NotificationModel>;
      _lastDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMore = result['hasMore'] as bool;

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    // Optimistic update
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].markAsRead();
      notifyListeners();
      await _notificationService.markAsRead(userId, notificationId);
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _currentUserId;
    if (userId == null) return;

    // Optimistic update
    _notifications = _notifications.map((n) => n.markAsRead()).toList();
    notifyListeners();

    await _notificationService.markAllAsRead(userId);
  }
}
