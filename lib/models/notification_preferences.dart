class NotificationPreferences {
  final bool matchEnabled;
  final bool messageEnabled;
  final bool eventEnabled;

  const NotificationPreferences({
    this.matchEnabled = true,
    this.messageEnabled = true,
    this.eventEnabled = true,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      matchEnabled: map['matchEnabled'] ?? true,
      messageEnabled: map['messageEnabled'] ?? true,
      eventEnabled: map['eventEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchEnabled': matchEnabled,
      'messageEnabled': messageEnabled,
      'eventEnabled': eventEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? matchEnabled,
    bool? messageEnabled,
    bool? eventEnabled,
  }) {
    return NotificationPreferences(
      matchEnabled: matchEnabled ?? this.matchEnabled,
      messageEnabled: messageEnabled ?? this.messageEnabled,
      eventEnabled: eventEnabled ?? this.eventEnabled,
    );
  }
}
