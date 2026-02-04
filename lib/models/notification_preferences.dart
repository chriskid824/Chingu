class NotificationPreferences {
  final bool enablePushNotifications;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool eventReminder;
  final bool eventChanges;
  final bool promotions;
  final bool newsletter;

  const NotificationPreferences({
    this.enablePushNotifications = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.eventReminder = true,
    this.eventChanges = true,
    this.promotions = false,
    this.newsletter = false,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChanges: map['eventChanges'] ?? true,
      promotions: map['promotions'] ?? false,
      newsletter: map['newsletter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'eventReminder': eventReminder,
      'eventChanges': eventChanges,
      'promotions': promotions,
      'newsletter': newsletter,
    };
  }

  NotificationPreferences copyWith({
    bool? enablePushNotifications,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? eventReminder,
    bool? eventChanges,
    bool? promotions,
    bool? newsletter,
  }) {
    return NotificationPreferences(
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChanges: eventChanges ?? this.eventChanges,
      promotions: promotions ?? this.promotions,
      newsletter: newsletter ?? this.newsletter,
    );
  }
}
