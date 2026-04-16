import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restaurant_model.dart';

/// 餐廳 CRUD + 篩選
class AdminRestaurantsProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<RestaurantModel> _all = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RestaurantModel> get all => _all;
  List<RestaurantModel> get active =>
      _all.where((r) => r.isActive).toList();
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final snap = await _db.collection('restaurants').get();
      _all = snap.docs.map((d) => RestaurantModel.fromFirestore(d)).toList();
    } catch (e) {
      _errorMessage = '載入餐廳失敗：$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> create(RestaurantModel restaurant) async {
    await _db.collection('restaurants').add(restaurant.toMap());
    await loadAll();
  }

  Future<void> update(RestaurantModel restaurant) async {
    await _db
        .collection('restaurants')
        .doc(restaurant.id)
        .update(restaurant.toMap());
    await loadAll();
  }

  Future<void> toggleActive(RestaurantModel restaurant) async {
    await _db
        .collection('restaurants')
        .doc(restaurant.id)
        .update({'isActive': !restaurant.isActive});
    await loadAll();
  }

  /// 篩選符合飲食/預算的餐廳，排除近 14 天指定過的
  List<RestaurantModel> filterFor({
    required Set<String> requiredDietary,
    required List<int> allowedBudgetLevels,
  }) {
    final fortnightAgo = DateTime.now().subtract(const Duration(days: 14));
    return active.where((r) {
      if (allowedBudgetLevels.isNotEmpty &&
          !allowedBudgetLevels.contains(r.budgetLevel)) {
        return false;
      }
      if (!r.supportsAllDietary(requiredDietary.toList())) return false;
      if (r.lastBookedAt != null && r.lastBookedAt!.isAfter(fortnightAgo)) {
        return false;
      }
      return true;
    }).toList();
  }
}
