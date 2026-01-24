/// 活動報名狀態
enum EventRegistrationStatus {
  /// 已報名/已確認
  registered,

  /// 候補名單
  waitlist,

  /// 已取消
  cancelled,

  /// 邀請中 (可選)
  pending,

  /// 拒絕 (可選)
  declined;

  String get toStr => name;

  static EventRegistrationStatus fromString(String status) {
    return EventRegistrationStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EventRegistrationStatus.pending,
    );
  }
}
