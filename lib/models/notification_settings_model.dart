/// 通知設置模型
class NotificationSettings {
  final bool notifyMatch;
  final bool notifyMessage;
  final bool notifyEvent;

  NotificationSettings({
    this.notifyMatch = true,
    this.notifyMessage = true,
    this.notifyEvent = true,
  });

  /// 從 Map 創建 NotificationSettings
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      notifyMatch: map['notifyMatch'] ?? true,
      notifyMessage: map['notifyMessage'] ?? true,
      notifyEvent: map['notifyEvent'] ?? true,
    );
  }

  /// 轉換為 Map
  Map<String, dynamic> toMap() {
    return {
      'notifyMatch': notifyMatch,
      'notifyMessage': notifyMessage,
      'notifyEvent': notifyEvent,
    };
  }

  /// 複製並更新
  NotificationSettings copyWith({
    bool? notifyMatch,
    bool? notifyMessage,
    bool? notifyEvent,
  }) {
    return NotificationSettings(
      notifyMatch: notifyMatch ?? this.notifyMatch,
      notifyMessage: notifyMessage ?? this.notifyMessage,
      notifyEvent: notifyEvent ?? this.notifyEvent,
    );
  }
}
