enum EventRegistrationStatus {
  registered,
  waitlist,
  cancelled,
  pending, // For approval if needed, or initial state
  declined,
}

extension EventRegistrationStatusExtension on EventRegistrationStatus {
  String toStringValue() {
    return toString().split('.').last;
  }

  static EventRegistrationStatus fromString(String status) {
    return EventRegistrationStatus.values.firstWhere(
      (e) => e.toStringValue() == status,
      orElse: () => EventRegistrationStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case EventRegistrationStatus.registered:
        return '已報名';
      case EventRegistrationStatus.waitlist:
        return '候補中';
      case EventRegistrationStatus.cancelled:
        return '已取消';
      case EventRegistrationStatus.pending:
        return '待確認';
      case EventRegistrationStatus.declined:
        return '已拒絕';
    }
  }
}
