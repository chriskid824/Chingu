/// 通知偏好設置模型
class NotificationPreferences {
  final bool enablePush;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool eventReminder;
  final bool eventChange;
  final bool promotions;
  final bool newsletter;

  const NotificationPreferences({
    this.enablePush = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.eventReminder = true,
    this.eventChange = true,
    this.promotions = false,
    this.newsletter = false,
  });

  /// 從 Map 創建 NotificationPreferences
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      enablePush: map['enablePush'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChange: map['eventChange'] ?? true,
      promotions: map['promotions'] ?? false,
      newsletter: map['newsletter'] ?? false,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'enablePush': enablePush,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'eventReminder': eventReminder,
      'eventChange': eventChange,
      'promotions': promotions,
      'newsletter': newsletter,
    };
  }

  /// 複製並更新
  NotificationPreferences copyWith({
    bool? enablePush,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? eventReminder,
    bool? eventChange,
    bool? promotions,
    bool? newsletter,
  }) {
    return NotificationPreferences(
      enablePush: enablePush ?? this.enablePush,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChange: eventChange ?? this.eventChange,
      promotions: promotions ?? this.promotions,
      newsletter: newsletter ?? this.newsletter,
    );
  }
}
