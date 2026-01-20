class NotificationSettings {
  final bool notifyPush;
  final bool notifyNewMatch;
  final bool notifyMatchSuccess;
  final bool notifyNewMessage;
  final bool showMessagePreview;
  final bool notifyEventReminder;
  final bool notifyEventChange;
  final bool notifyMarketing;
  final bool notifyNewsletter;
  final List<String> subscribedRegions;
  final List<String> subscribedInterests;

  const NotificationSettings({
    this.notifyPush = true,
    this.notifyNewMatch = true,
    this.notifyMatchSuccess = true,
    this.notifyNewMessage = true,
    this.showMessagePreview = true,
    this.notifyEventReminder = true,
    this.notifyEventChange = true,
    this.notifyMarketing = false,
    this.notifyNewsletter = false,
    this.subscribedRegions = const [],
    this.subscribedInterests = const [],
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      notifyPush: map['notifyPush'] ?? true,
      notifyNewMatch: map['notifyNewMatch'] ?? true,
      notifyMatchSuccess: map['notifyMatchSuccess'] ?? true,
      notifyNewMessage: map['notifyNewMessage'] ?? true,
      showMessagePreview: map['showMessagePreview'] ?? true,
      notifyEventReminder: map['notifyEventReminder'] ?? true,
      notifyEventChange: map['notifyEventChange'] ?? true,
      notifyMarketing: map['notifyMarketing'] ?? false,
      notifyNewsletter: map['notifyNewsletter'] ?? false,
      subscribedRegions: List<String>.from(map['subscribedRegions'] ?? []),
      subscribedInterests: List<String>.from(map['subscribedInterests'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notifyPush': notifyPush,
      'notifyNewMatch': notifyNewMatch,
      'notifyMatchSuccess': notifyMatchSuccess,
      'notifyNewMessage': notifyNewMessage,
      'showMessagePreview': showMessagePreview,
      'notifyEventReminder': notifyEventReminder,
      'notifyEventChange': notifyEventChange,
      'notifyMarketing': notifyMarketing,
      'notifyNewsletter': notifyNewsletter,
      'subscribedRegions': subscribedRegions,
      'subscribedInterests': subscribedInterests,
    };
  }

  NotificationSettings copyWith({
    bool? notifyPush,
    bool? notifyNewMatch,
    bool? notifyMatchSuccess,
    bool? notifyNewMessage,
    bool? showMessagePreview,
    bool? notifyEventReminder,
    bool? notifyEventChange,
    bool? notifyMarketing,
    bool? notifyNewsletter,
    List<String>? subscribedRegions,
    List<String>? subscribedInterests,
  }) {
    return NotificationSettings(
      notifyPush: notifyPush ?? this.notifyPush,
      notifyNewMatch: notifyNewMatch ?? this.notifyNewMatch,
      notifyMatchSuccess: notifyMatchSuccess ?? this.notifyMatchSuccess,
      notifyNewMessage: notifyNewMessage ?? this.notifyNewMessage,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      notifyEventReminder: notifyEventReminder ?? this.notifyEventReminder,
      notifyEventChange: notifyEventChange ?? this.notifyEventChange,
      notifyMarketing: notifyMarketing ?? this.notifyMarketing,
      notifyNewsletter: notifyNewsletter ?? this.notifyNewsletter,
      subscribedRegions: subscribedRegions ?? this.subscribedRegions,
      subscribedInterests: subscribedInterests ?? this.subscribedInterests,
    );
  }
}
