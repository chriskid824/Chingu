class NotificationSettings {
  final bool pushEnabled;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool eventUpdate;
  final bool systemUpdate;

  const NotificationSettings({
    this.pushEnabled = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.eventUpdate = true,
    this.systemUpdate = true,
  });

  /// 從 Map 創建 NotificationSettings
  factory NotificationSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const NotificationSettings();

    return NotificationSettings(
      pushEnabled: map['pushEnabled'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventUpdate: map['eventUpdate'] ?? true,
      systemUpdate: map['systemUpdate'] ?? true,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'eventUpdate': eventUpdate,
      'systemUpdate': systemUpdate,
    };
  }

  /// 複製並更新
  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? eventUpdate,
    bool? systemUpdate,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      eventUpdate: eventUpdate ?? this.eventUpdate,
      systemUpdate: systemUpdate ?? this.systemUpdate,
    );
  }
}
