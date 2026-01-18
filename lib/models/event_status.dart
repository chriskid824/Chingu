enum EventStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String toStringValue() {
    return name;
  }

  static EventStatus fromString(String status) {
    try {
      return EventStatus.values.firstWhere((e) => e.name == status);
    } catch (_) {
      return EventStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case EventStatus.pending:
        return '等待配對';
      case EventStatus.confirmed:
        return '已確認';
      case EventStatus.completed:
        return '已完成';
      case EventStatus.cancelled:
        return '已取消';
    }
  }
}
