enum EventStatus {
  open,      // Open for registration
  full,      // Capacity reached, waitlist available
  cancelled, // Cancelled by system or lack of participants
  completed, // Event finished
  closed,    // Deadline passed
}

extension EventStatusExtension on EventStatus {
  String toStringValue() {
    return toString().split('.').last;
  }

  static EventStatus fromString(String status) {
    return EventStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => EventStatus.open,
    );
  }

  String get displayName {
    switch (this) {
      case EventStatus.open:
        return '報名中';
      case EventStatus.full:
        return '已額滿';
      case EventStatus.cancelled:
        return '已取消';
      case EventStatus.completed:
        return '已完成';
      case EventStatus.closed:
        return '報名截止';
    }
  }
}
