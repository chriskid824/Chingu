class NotificationSettingsModel {
  final bool pushEnabled;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool showMessagePreview;
  final bool eventReminder;
  final bool eventChanges;
  final bool marketingPromotion;
  final bool marketingNewsletter;

  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.showMessagePreview = true,
    this.eventReminder = true,
    this.eventChanges = true,
    this.marketingPromotion = false,
    this.marketingNewsletter = false,
  });

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      pushEnabled: map['pushEnabled'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      showMessagePreview: map['showMessagePreview'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChanges: map['eventChanges'] ?? true,
      marketingPromotion: map['marketingPromotion'] ?? false,
      marketingNewsletter: map['marketingNewsletter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'showMessagePreview': showMessagePreview,
      'eventReminder': eventReminder,
      'eventChanges': eventChanges,
      'marketingPromotion': marketingPromotion,
      'marketingNewsletter': marketingNewsletter,
    };
  }

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? showMessagePreview,
    bool? eventReminder,
    bool? eventChanges,
    bool? marketingPromotion,
    bool? marketingNewsletter,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChanges: eventChanges ?? this.eventChanges,
      marketingPromotion: marketingPromotion ?? this.marketingPromotion,
      marketingNewsletter: marketingNewsletter ?? this.marketingNewsletter,
    );
  }
}
