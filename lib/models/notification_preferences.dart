class NotificationPreferences {
  final bool newMatch;
  final bool newMessage;
  final bool matchSuccess;
  final bool eventReminder;
  final bool systemUpdate;

  const NotificationPreferences({
    this.newMatch = true,
    this.newMessage = true,
    this.matchSuccess = true,
    this.eventReminder = true,
    this.systemUpdate = true,
  });

  /// 從 Map 創建 NotificationPreferences
  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      newMatch: map['newMatch'] ?? true,
      newMessage: map['newMessage'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      systemUpdate: map['systemUpdate'] ?? true,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'newMatch': newMatch,
      'newMessage': newMessage,
      'matchSuccess': matchSuccess,
      'eventReminder': eventReminder,
      'systemUpdate': systemUpdate,
    };
  }

  /// 複製並更新
  NotificationPreferences copyWith({
    bool? newMatch,
    bool? newMessage,
    bool? matchSuccess,
    bool? eventReminder,
    bool? systemUpdate,
  }) {
    return NotificationPreferences(
      newMatch: newMatch ?? this.newMatch,
      newMessage: newMessage ?? this.newMessage,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      eventReminder: eventReminder ?? this.eventReminder,
      systemUpdate: systemUpdate ?? this.systemUpdate,
    );
  }
}
