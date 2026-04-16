import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dinner_group_model.dart';
import '../../models/user_model.dart';
import '../../models/restaurant_model.dart';

/// 本週 DinnerGroups 載入 + 餐廳指定 + 訂位狀態管理
class AdminGroupsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<DinnerGroupModel> _groups = [];
  Map<String, List<UserModel>> _participantsByGroup = {};
  String? _currentEventId;
  bool _isLoading = false;
  String? _errorMessage;

  List<DinnerGroupModel> get groups => _groups;
  Map<String, List<UserModel>> get participantsByGroup => _participantsByGroup;
  String? get currentEventId => _currentEventId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 載入本週進行中 Event 的所有分組
  Future<void> loadCurrentWeek() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final now = DateTime.now();
      final since = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 7));
      final eventSnap = await _db
          .collection('dinner_events')
          .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('eventDate')
          .limit(1)
          .get();

      if (eventSnap.docs.isEmpty) {
        _groups = [];
        _participantsByGroup = {};
        _currentEventId = null;
        return;
      }

      _currentEventId = eventSnap.docs.first.id;

      final groupSnap = await _db
          .collection('dinner_groups')
          .where('eventId', isEqualTo: _currentEventId)
          .get();

      _groups = groupSnap.docs
          .map((d) => DinnerGroupModel.fromFirestore(d))
          .toList();

      await _loadParticipants();
    } catch (e) {
      _errorMessage = '載入失敗：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadParticipants() async {
    final allUids = _groups.expand((g) => g.participantIds).toSet().toList();
    if (allUids.isEmpty) return;

    // Firestore in 查詢限制 30 個
    final users = <UserModel>[];
    for (var i = 0; i < allUids.length; i += 30) {
      final chunk = allUids.sublist(
        i,
        i + 30 > allUids.length ? allUids.length : i + 30,
      );
      final snap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snap.docs.map((d) => UserModel.fromFirestore(d)));
    }
    final byUid = {for (var u in users) u.uid: u};

    _participantsByGroup = {
      for (var g in _groups)
        g.id: g.participantIds
            .map((uid) => byUid[uid])
            .whereType<UserModel>()
            .toList(),
    };
  }

  /// 指定餐廳給某組（同步寫入 group + 更新 restaurant.lastBookedAt）
  Future<void> assignRestaurant(
    String groupId,
    RestaurantModel restaurant,
  ) async {
    final batch = _db.batch();
    batch.update(_db.collection('dinner_groups').doc(groupId), {
      'restaurantId': restaurant.id,
      'restaurantName': restaurant.name,
      'restaurantAddress': restaurant.address,
      'restaurantLocation': restaurant.location,
      'restaurantPhone': restaurant.phone,
      'restaurantImageUrl': restaurant.imageUrl,
      'bookingStatus': 'pending',
    });
    batch.update(_db.collection('restaurants').doc(restaurant.id), {
      'lastBookedAt': Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
    await loadCurrentWeek();
  }

  /// 訂位狀態切換
  Future<void> setBookingStatus(String groupId, String status) async {
    await _db.collection('dinner_groups').doc(groupId).update({
      'bookingStatus': status,
    });
    await loadCurrentWeek();
  }

  /// 計算某組的飲食禁忌聯集
  Set<String> dietaryUnion(String groupId) {
    final users = _participantsByGroup[groupId] ?? [];
    return users
        .expand((u) => u.dietaryPreferences)
        .where((d) => d != 'none')
        .toSet();
  }

  /// 計算某組的預算交集 (回傳允許的 budgetRange list)
  List<int> budgetIntersection(String groupId) {
    final users = _participantsByGroup[groupId] ?? [];
    if (users.isEmpty) return [];
    final ranges = users.map((u) => u.budgetRange).toSet();
    return ranges.toList()..sort();
  }
}
