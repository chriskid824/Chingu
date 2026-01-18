class NotificationSettingsModel {
  final bool matchNotifications;
  final bool messageNotifications;
  final bool eventNotifications;

  const NotificationSettingsModel({
    this.matchNotifications = true,
    this.messageNotifications = true,
    this.eventNotifications = true,
  });

  /// 從 Map 創建 NotificationSettingsModel
  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      matchNotifications: map['matchNotifications'] ?? true,
      messageNotifications: map['messageNotifications'] ?? true,
      eventNotifications: map['eventNotifications'] ?? true,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'matchNotifications': matchNotifications,
      'messageNotifications': messageNotifications,
      'eventNotifications': eventNotifications,
    };
  }

  /// 複製並更新
  NotificationSettingsModel copyWith({
    bool? matchNotifications,
    bool? messageNotifications,
    bool? eventNotifications,
  }) {
    return NotificationSettingsModel(
      matchNotifications: matchNotifications ?? this.matchNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      eventNotifications: eventNotifications ?? this.eventNotifications,
    );
  }
}
