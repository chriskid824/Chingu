class NotificationSettings {
  final bool enablePushNotifications;
  final bool notifyNewMatch;
  final bool notifyMatchSuccess;
  final bool notifyNewMessage;
  final bool showMessagePreview;
  final bool notifyAppointmentReminder;
  final bool notifyAppointmentChange;
  final bool notifyPromotions;
  final bool notifyNewsletter;

  const NotificationSettings({
    this.enablePushNotifications = true,
    this.notifyNewMatch = true,
    this.notifyMatchSuccess = true,
    this.notifyNewMessage = true,
    this.showMessagePreview = true,
    this.notifyAppointmentReminder = true,
    this.notifyAppointmentChange = true,
    this.notifyPromotions = false,
    this.notifyNewsletter = false,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enablePushNotifications: map['enablePushNotifications'] ?? true,
      notifyNewMatch: map['notifyNewMatch'] ?? true,
      notifyMatchSuccess: map['notifyMatchSuccess'] ?? true,
      notifyNewMessage: map['notifyNewMessage'] ?? true,
      showMessagePreview: map['showMessagePreview'] ?? true,
      notifyAppointmentReminder: map['notifyAppointmentReminder'] ?? true,
      notifyAppointmentChange: map['notifyAppointmentChange'] ?? true,
      notifyPromotions: map['notifyPromotions'] ?? false,
      notifyNewsletter: map['notifyNewsletter'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enablePushNotifications': enablePushNotifications,
      'notifyNewMatch': notifyNewMatch,
      'notifyMatchSuccess': notifyMatchSuccess,
      'notifyNewMessage': notifyNewMessage,
      'showMessagePreview': showMessagePreview,
      'notifyAppointmentReminder': notifyAppointmentReminder,
      'notifyAppointmentChange': notifyAppointmentChange,
      'notifyPromotions': notifyPromotions,
      'notifyNewsletter': notifyNewsletter,
    };
  }

  NotificationSettings copyWith({
    bool? enablePushNotifications,
    bool? notifyNewMatch,
    bool? notifyMatchSuccess,
    bool? notifyNewMessage,
    bool? showMessagePreview,
    bool? notifyAppointmentReminder,
    bool? notifyAppointmentChange,
    bool? notifyPromotions,
    bool? notifyNewsletter,
  }) {
    return NotificationSettings(
      enablePushNotifications: enablePushNotifications ?? this.enablePushNotifications,
      notifyNewMatch: notifyNewMatch ?? this.notifyNewMatch,
      notifyMatchSuccess: notifyMatchSuccess ?? this.notifyMatchSuccess,
      notifyNewMessage: notifyNewMessage ?? this.notifyNewMessage,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      notifyAppointmentReminder: notifyAppointmentReminder ?? this.notifyAppointmentReminder,
      notifyAppointmentChange: notifyAppointmentChange ?? this.notifyAppointmentChange,
      notifyPromotions: notifyPromotions ?? this.notifyPromotions,
      notifyNewsletter: notifyNewsletter ?? this.notifyNewsletter,
    );
  }
}
