import 'package:flutter/material.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/services/dinner_event_service.dart';

class DinnerEventProvider with ChangeNotifier {
  final DinnerEventService _dinnerEventService;

  DinnerEventProvider({DinnerEventService? dinnerEventService})
      : _dinnerEventService = dinnerEventService ?? DinnerEventService();

  List<DinnerEventModel> _myEvents = [];
  List<DinnerEventModel> _recommendedEvents = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DinnerEventModel> get myEvents => _myEvents;
  List<DinnerEventModel> get recommendedEvents => _recommendedEvents;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 創建活動
  Future<bool> createEvent({
    required String userId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.createEvent(
        userId: userId,
        dateTime: dateTime,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
      );

      // 創建成功後刷新我的活動列表
      await fetchMyEvents(userId);

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 獲取我的活動列表
  Future<void> fetchMyEvents(String userId) async {
    try {
      _setLoading(true);
      _myEvents = await _dinnerEventService.getUserEvents(userId);
      // 按日期升序排列，最近的在前
      _myEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));
      _setLoading(false);
    } catch (e) {
      debugPrint('獲取我的活動失敗: $e');
      _setLoading(false);
    }
  }

  /// 獲取推薦活動
  Future<void> fetchRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    try {
      _setLoading(true);
      _recommendedEvents = await _dinnerEventService.getRecommendedEvents(
        city: city,
        budgetRange: budgetRange,
        excludeEventIds: excludeEventIds,
      );
      _setLoading(false);
    } catch (e) {
      debugPrint('獲取推薦活動失敗: $e');
      _setLoading(false);
    }
  }

  /// 加入活動
  Future<bool> joinEvent(String eventId, String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.joinEvent(eventId, userId);
      
      // 刷新列表
      await fetchMyEvents(userId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 退出活動
  Future<bool> leaveEvent(String eventId, String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.leaveEvent(eventId, userId);
      
      // 刷新列表
      await fetchMyEvents(userId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  /// 獲取本週四和下週四的日期
  List<DateTime> getThursdayDates() {
    return _dinnerEventService.getThursdayDates();
  }

  /// 獲取可預約的日期
  /// 過濾規則：
  /// 1. 報名截止時間：該週週二中午 12:00
  /// 2. 同時未完成報名上限：3 場
  List<DateTime> getBookableDates() {
    final dates = _dinnerEventService.getThursdayDates();
    final now = DateTime.now();
    
    return dates.where((date) {
      // 1. 檢查截止時間（該週二中午 12:00）
      // Thursday.weekday = 4, Tuesday.weekday = 2 → 差 2 天
      final tuesday = DateTime(date.year, date.month, date.day)
          .subtract(const Duration(days: 2));
      final deadline = DateTime(tuesday.year, tuesday.month, tuesday.day, 12, 0);
      
      if (now.isAfter(deadline)) {
        return false;
      }

      return true;
    }).toList();
  }

  /// 檢查某日期是否已報名
  bool isDateBooked(DateTime date) {
    return _myEvents.any((event) {
      final eventDate = event.eventDate;
      return eventDate.year == date.year &&
             eventDate.month == date.month &&
             eventDate.day == date.day;
    });
  }

  /// 同時未完成報名上限
  static const int maxActiveBookings = 3;

  /// 目前的有效報名數（未來的 open/matching 活動）
  int get activeBookingCount {
    final now = DateTime.now();
    return _myEvents.where((event) {
      return event.eventDate.isAfter(now) &&
             (event.status == 'open' || event.status == 'matching');
    }).length;
  }

  /// 是否還能報名
  bool get canBookMore => activeBookingCount < maxActiveBookings;

  /// 預約活動
  Future<bool> bookEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.joinOrCreateEvent(
        userId: userId,
        date: date,
        city: city,
        district: district,
      );
      
      // 刷新列表
      await fetchMyEvents(userId);
      
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}



