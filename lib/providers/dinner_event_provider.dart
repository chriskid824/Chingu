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
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
    int maxParticipants = 6,
    DateTime? registrationDeadline,
  }) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.createEvent(
        creatorId: creatorId,
        dateTime: dateTime,
        budgetRange: budgetRange,
        city: city,
        district: district,
        notes: notes,
        maxParticipants: maxParticipants,
        registrationDeadline: registrationDeadline,
      );

      // 創建成功後刷新我的活動列表
      await fetchMyEvents(creatorId);

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

  /// 取消活動
  Future<bool> cancelEvent(String eventId, String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      await _dinnerEventService.cancelEvent(eventId);

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
  List<DateTime> getBookableDates() {
    final dates = _dinnerEventService.getThursdayDates();
    final now = DateTime.now();
    
    return dates.where((date) {
      final monday = DateTime(date.year, date.month, date.day).subtract(const Duration(days: 3));
      if (now.isAfter(monday)) {
        return false;
      }

      final isJoined = _myEvents.any((event) {
        final eventDate = event.dateTime;
        return eventDate.year == date.year && 
               eventDate.month == date.month && 
               eventDate.day == date.day;
      });

      if (isJoined) {
        return false;
      }

      return true;
    }).toList();
  }

  bool get canBookMore => getBookableDates().isNotEmpty;

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
