import 'package:flutter/foundation.dart';

class NotificationSettingsModel {
  final bool pushEnabled;
  final bool newMatch;
  final bool matchSuccess;
  final bool newMessage;
  final bool messagePreview;
  final bool eventReminder;
  final bool eventChange;
  final bool promo;
  final bool newsletter;
  final List<String> subscribedRegions;
  final List<String> subscribedInterests;

  const NotificationSettingsModel({
    this.pushEnabled = true,
    this.newMatch = true,
    this.matchSuccess = true,
    this.newMessage = true,
    this.messagePreview = true,
    this.eventReminder = true,
    this.eventChange = true,
    this.promo = false,
    this.newsletter = false,
    this.subscribedRegions = const [],
    this.subscribedInterests = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'newMatch': newMatch,
      'matchSuccess': matchSuccess,
      'newMessage': newMessage,
      'messagePreview': messagePreview,
      'eventReminder': eventReminder,
      'eventChange': eventChange,
      'promo': promo,
      'newsletter': newsletter,
      'subscribedRegions': subscribedRegions,
      'subscribedInterests': subscribedInterests,
    };
  }

  factory NotificationSettingsModel.fromMap(Map<String, dynamic> map) {
    return NotificationSettingsModel(
      pushEnabled: map['pushEnabled'] ?? true,
      newMatch: map['newMatch'] ?? true,
      matchSuccess: map['matchSuccess'] ?? true,
      newMessage: map['newMessage'] ?? true,
      messagePreview: map['messagePreview'] ?? true,
      eventReminder: map['eventReminder'] ?? true,
      eventChange: map['eventChange'] ?? true,
      promo: map['promo'] ?? false,
      newsletter: map['newsletter'] ?? false,
      subscribedRegions: List<String>.from(map['subscribedRegions'] ?? []),
      subscribedInterests: List<String>.from(map['subscribedInterests'] ?? []),
    );
  }

  NotificationSettingsModel copyWith({
    bool? pushEnabled,
    bool? newMatch,
    bool? matchSuccess,
    bool? newMessage,
    bool? messagePreview,
    bool? eventReminder,
    bool? eventChange,
    bool? promo,
    bool? newsletter,
    List<String>? subscribedRegions,
    List<String>? subscribedInterests,
  }) {
    return NotificationSettingsModel(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      newMatch: newMatch ?? this.newMatch,
      matchSuccess: matchSuccess ?? this.matchSuccess,
      newMessage: newMessage ?? this.newMessage,
      messagePreview: messagePreview ?? this.messagePreview,
      eventReminder: eventReminder ?? this.eventReminder,
      eventChange: eventChange ?? this.eventChange,
      promo: promo ?? this.promo,
      newsletter: newsletter ?? this.newsletter,
      subscribedRegions: subscribedRegions ?? this.subscribedRegions,
      subscribedInterests: subscribedInterests ?? this.subscribedInterests,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationSettingsModel &&
      other.pushEnabled == pushEnabled &&
      other.newMatch == newMatch &&
      other.matchSuccess == matchSuccess &&
      other.newMessage == newMessage &&
      other.messagePreview == messagePreview &&
      other.eventReminder == eventReminder &&
      other.eventChange == eventChange &&
      other.promo == promo &&
      other.newsletter == newsletter &&
      listEquals(other.subscribedRegions, subscribedRegions) &&
      listEquals(other.subscribedInterests, subscribedInterests);
  }

  @override
  int get hashCode {
    return pushEnabled.hashCode ^
      newMatch.hashCode ^
      matchSuccess.hashCode ^
      newMessage.hashCode ^
      messagePreview.hashCode ^
      eventReminder.hashCode ^
      eventChange.hashCode ^
      promo.hashCode ^
      newsletter.hashCode ^
      subscribedRegions.hashCode ^
      subscribedInterests.hashCode;
  }
}
