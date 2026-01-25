enum EventRegistrationStatus {
  registered,
  waitlist,
  cancelled;

  String get label {
    switch (this) {
      case EventRegistrationStatus.registered:
        return '已報名';
      case EventRegistrationStatus.waitlist:
        return '候補中';
      case EventRegistrationStatus.cancelled:
        return '已取消';
    }
  }
}
