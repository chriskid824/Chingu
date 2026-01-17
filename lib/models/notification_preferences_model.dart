class NotificationPreferences {
  final bool enablePush;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool showMessagePreview;
  final bool eventReminder;
  final bool eventChange;
  final bool marketingPromo;
  final bool marketingNewsletter;

  const NotificationPreferences({
    this.enablePush = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.showMessagePreview = true,
    this.eventReminder = true,
    this.eventChange = true,
    this.marketingPromo = false,
    this.marketingNewsletter = false,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      enablePush: map['enablePush'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      showMessagePreview: map['showMessagePreview'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChange: map['eventChange'] ?? true,
      marketingPromo: map['marketingPromo'] ?? false,
      marketingNewsletter: map['marketingNewsletter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enablePush': enablePush,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'showMessagePreview': showMessagePreview,
      'eventReminder': eventReminder,
      'eventChange': eventChange,
      'marketingPromo': marketingPromo,
      'marketingNewsletter': marketingNewsletter,
    };
  }

  NotificationPreferences copyWith({
    bool? enablePush,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? showMessagePreview,
    bool? eventReminder,
    bool? eventChange,
    bool? marketingPromo,
    bool? marketingNewsletter,
  }) {
    return NotificationPreferences(
      enablePush: enablePush ?? this.enablePush,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChange: eventChange ?? this.eventChange,
      marketingPromo: marketingPromo ?? this.marketingPromo,
      marketingNewsletter: marketingNewsletter ?? this.marketingNewsletter,
    );
  }
}
