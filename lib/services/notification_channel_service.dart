import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 負責管理 Android 通知頻道的服務
class NotificationChannelService {
  // === 配對通知頻道 ===
  static const String channelIdMatches = 'channel_matches';
  static const String channelNameMatches = '配對通知';
  static const String channelDescMatches = '當有新配對或配對成功時的通知';

  // === 訊息通知頻道 ===
  static const String channelIdMessages = 'channel_messages';
  static const String channelNameMessages = '訊息通知';
  static const String channelDescMessages = '收到新訊息時的通知';

  // === 活動通知頻道 ===
  static const String channelIdEvents = 'channel_events';
  static const String channelNameEvents = '活動通知';
  static const String channelDescEvents = '晚餐預約提醒與變更通知';

  // === 行銷通知頻道 ===
  static const String channelIdMarketing = 'channel_marketing';
  static const String channelNameMarketing = '行銷通知';
  static const String channelDescMarketing = '優惠活動與電子報';

  // === 系統通知頻道 ===
  static const String channelIdSystem = 'channel_system';
  static const String channelNameSystem = '系統通知';
  static const String channelDescSystem = '一般系統通知';

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 建立所有 Android 通知頻道
  Future<void> createNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation == null) {
      return;
    }

    // 定義頻道列表
    final List<AndroidNotificationChannel> channels = [
      // 配對通知 (高重要性)
      const AndroidNotificationChannel(
        channelIdMatches,
        channelNameMatches,
        description: channelDescMatches,
        importance: Importance.high,
        playSound: true,
      ),
      // 訊息通知 (高重要性)
      const AndroidNotificationChannel(
        channelIdMessages,
        channelNameMessages,
        description: channelDescMessages,
        importance: Importance.high,
        playSound: true,
      ),
      // 活動通知 (高重要性)
      const AndroidNotificationChannel(
        channelIdEvents,
        channelNameEvents,
        description: channelDescEvents,
        importance: Importance.high,
        playSound: true,
      ),
      // 行銷通知 (預設重要性)
      const AndroidNotificationChannel(
        channelIdMarketing,
        channelNameMarketing,
        description: channelDescMarketing,
        importance: Importance.defaultImportance,
        playSound: true,
      ),
      // 系統通知 (預設重要性)
      const AndroidNotificationChannel(
        channelIdSystem,
        channelNameSystem,
        description: channelDescSystem,
        importance: Importance.defaultImportance,
        playSound: true,
      ),
    ];

    // 建立所有頻道
    for (final channel in channels) {
      await androidImplementation.createNotificationChannel(channel);
    }
  }
}
