class NotificationSettings {
  final bool pushEnabled;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool eventReminder;
  final bool eventChange;
  final bool marketingPromo;
  final bool marketingNewsletter;

  const NotificationSettings({
    this.pushEnabled = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.eventReminder = true,
    this.eventChange = true,
    this.marketingPromo = false,
    this.marketingNewsletter = false,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      pushEnabled: map['pushEnabled'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChange: map['eventChange'] ?? true,
      marketingPromo: map['marketingPromo'] ?? false,
      marketingNewsletter: map['marketingNewsletter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'eventReminder': eventReminder,
      'eventChange': eventChange,
      'marketingPromo': marketingPromo,
      'marketingNewsletter': marketingNewsletter,
    };
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? eventReminder,
    bool? eventChange,
    bool? marketingPromo,
    bool? marketingNewsletter,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChange: eventChange ?? this.eventChange,
      marketingPromo: marketingPromo ?? this.marketingPromo,
      marketingNewsletter: marketingNewsletter ?? this.marketingNewsletter,
    );
  }
}
