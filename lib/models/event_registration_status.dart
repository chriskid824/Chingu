enum EventRegistrationStatus {
  registered,
  waitlist,
  cancelled,
}

extension EventRegistrationStatusExtension on EventRegistrationStatus {
  String toStringValue() {
    return toString().split('.').last;
  }

  static EventRegistrationStatus fromString(String status) {
    return EventRegistrationStatus.values.firstWhere(
      (e) => e.toStringValue() == status,
      orElse: () => EventRegistrationStatus.cancelled,
    );
  }
}
