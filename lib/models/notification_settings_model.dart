class NotificationSettings {
  final bool pushEnabled;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool eventUpdate;
  final bool systemUpdate;
  final List<String> subscribedRegions;
  final List<String> subscribedInterests;

  const NotificationSettings({
    this.pushEnabled = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.eventUpdate = true,
    this.systemUpdate = true,
    this.subscribedRegions = const [],
    this.subscribedInterests = const [],
  });

  /// 創建預設設定
  factory NotificationSettings.defaults() {
    return const NotificationSettings();
  }

  /// 從 Map 創建 NotificationSettings
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      pushEnabled: map['pushEnabled'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventUpdate: map['eventUpdate'] ?? true,
      systemUpdate: map['systemUpdate'] ?? true,
      subscribedRegions: List<String>.from(map['subscribedRegions'] ?? []),
      subscribedInterests: List<String>.from(map['subscribedInterests'] ?? []),
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
      'subscribedRegions': subscribedRegions,
      'subscribedInterests': subscribedInterests,
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
    List<String>? subscribedRegions,
    List<String>? subscribedInterests,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      eventUpdate: eventUpdate ?? this.eventUpdate,
      systemUpdate: systemUpdate ?? this.systemUpdate,
      subscribedRegions: subscribedRegions ?? this.subscribedRegions,
      subscribedInterests: subscribedInterests ?? this.subscribedInterests,
    );
  }
}
