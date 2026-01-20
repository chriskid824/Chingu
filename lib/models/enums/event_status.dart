enum EventStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get label {
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

  static EventStatus fromString(String status) {
    return EventStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EventStatus.pending,
    );
  }
}
