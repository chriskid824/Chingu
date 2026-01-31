import 'package:flutter/material.dart';

enum EventStatus {
  pending,
  confirmed,
  full,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case EventStatus.pending:
        return '等待配對';
      case EventStatus.confirmed:
        return '已確認';
      case EventStatus.full:
        return '已額滿';
      case EventStatus.completed:
        return '已完成';
      case EventStatus.cancelled:
        return '已取消';
    }
  }

  Color get color {
    switch (this) {
      case EventStatus.pending:
        return Colors.orange;
      case EventStatus.confirmed:
        return Colors.green;
      case EventStatus.full:
        return Colors.red;
      case EventStatus.completed:
        return Colors.blue;
      case EventStatus.cancelled:
        return Colors.grey;
    }
  }

  static EventStatus fromString(String status) {
    return EventStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EventStatus.pending,
    );
  }
}
