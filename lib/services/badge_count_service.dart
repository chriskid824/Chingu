class BadgeCountService {
  static final BadgeCountService _instance = BadgeCountService._internal();

  factory BadgeCountService() {
    return _instance;
  }

  BadgeCountService._internal();

  int _currentCount = 0;

  /// Updates the application badge count.
  ///
  /// Since no native badge package is currently installed, this logs the count.
  Future<void> updateCount(int count) async {
    _currentCount = count;
    // In a real implementation with flutter_app_badger:
    // if (await FlutterAppBadger.isAppBadgeSupported()) {
    //   FlutterAppBadger.updateBadgeCount(count);
    // }
    print('BadgeCountService: Updated badge count to $count');
  }

  /// Removes the application badge.
  Future<void> removeBadge() async {
    _currentCount = 0;
    // if (await FlutterAppBadger.isAppBadgeSupported()) {
    //   FlutterAppBadger.removeBadge();
    // }
    print('BadgeCountService: Removed badge');
  }

  /// Resets the count to 0.
  Future<void> reset() async {
    await removeBadge();
  }
}
