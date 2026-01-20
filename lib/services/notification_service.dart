import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:chingu/models/notification_settings_model.dart';
import 'package:chingu/services/rich_notification_service.dart';

class NotificationService {
  // Singleton
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isInitialized = false;

  /// 初始化服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 請求權限
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 監聽前景訊息
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 監聽背景訊息點擊
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 檢查是否有初始訊息（從終止狀態開啟）
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
    }
  }

  /// 處理前景訊息
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.messageId}');

    // 如果有 notification 內容，顯示本地通知
    if (message.notification != null) {
      // 這裡可以整合 RichNotificationService
      // 但需要將 RemoteMessage 轉換為 NotificationModel 或直接顯示
      // 暫時簡單實作，假設 RichNotificationService 有直接顯示的方法或我們手動調用 flutter_local_notifications
      // 為了保持一致性，我們應該解析 data 並使用 RichNotificationService
      // 但由於 RichNotificationService 需要 NotificationModel，我們可能需要一個適配器
    }
  }

  /// 處理訊息點擊
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Message opened app: ${message.messageId}');
    // 這裡的邏輯可能需要與 RichNotificationService 整合
    // 目前 RichNotificationService 處理本地通知的點擊
    // 遠端通知點擊通常由 Firebase SDK 處理，但如果需要特定導航邏輯：
    if (message.data.isNotEmpty) {
      final actionType = message.data['actionType'];
      final actionData = message.data['actionData'];
      // 使用 RichNotificationService 的導航邏輯（需要公開或透過 AppRouter）
      // 由於 RichNotificationService 是 singleton 且有些方法是私有的，
      // 我們可能需要修改 RichNotificationService 來公開 handleNavigation
      // 但根據現有代碼，我們暫時不做，因為這不是本次任務的重點（主題訂閱）
    }
  }

  /// 同步訂閱狀態
  Future<void> syncSubscriptions(
    NotificationSettings? oldSettings,
    NotificationSettings newSettings
  ) async {
    // 處理地區訂閱
    final oldRegions = oldSettings?.subscribedRegions.toSet() ?? {};
    final newRegions = newSettings.subscribedRegions.toSet();

    // 取消訂閱已移除的地區
    for (final region in oldRegions.difference(newRegions)) {
      await _unsubscribeFromTopic(_getRegionTopic(region));
    }
    // 訂閱新增的地區
    for (final region in newRegions.difference(oldRegions)) {
      await _subscribeToTopic(_getRegionTopic(region));
    }

    // 處理興趣訂閱
    final oldInterests = oldSettings?.subscribedInterests.toSet() ?? {};
    final newInterests = newSettings.subscribedInterests.toSet();

    // 取消訂閱已移除的興趣
    for (final interest in oldInterests.difference(newInterests)) {
      await _unsubscribeFromTopic(_getInterestTopic(interest));
    }
    // 訂閱新增的興趣
    for (final interest in newInterests.difference(oldInterests)) {
      await _subscribeToTopic(_getInterestTopic(interest));
    }
  }

  /// 清除所有訂閱（登出時調用）
  Future<void> reset() async {
    try {
      await _messaging.deleteToken();
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error resetting notification service: $e');
    }
  }

  Future<void> _subscribeToTopic(String topic) async {
    try {
      debugPrint('Subscribing to topic: $topic');
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  Future<void> _unsubscribeFromTopic(String topic) async {
    try {
      debugPrint('Unsubscribing from topic: $topic');
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  String _getRegionTopic(String region) {
    // region 應該是英文 ID (taipei, taichung, kaohsiung)
    // 如果是中文，需要映射或編碼
    // 假設 UI 傳遞的是英文 ID 或我們在此處理
    // 根據需求描述 "taipei/taichung/kaohsiung"，假設是英文
    // 但如果 UI 顯示中文，需要確認傳入的值
    return 'region_${Uri.encodeComponent(region.toLowerCase())}';
  }

  String _getInterestTopic(String interest) {
    // 興趣可能是中文，使用 URI encode
    return 'interest_${Uri.encodeComponent(interest)}';
  }
}
