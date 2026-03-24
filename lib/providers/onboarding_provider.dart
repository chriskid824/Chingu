import 'package:flutter/material.dart';
import 'package:chingu/providers/auth_provider.dart';

/// Onboarding 數據提供者 - 管理4步驟設定流程的臨時數據
class OnboardingProvider with ChangeNotifier {
  // Step 1: 基本資料
  String? _name;
  int? _age;
  String? _gender; // 'male', 'female', 'non_binary', 'undisclosed'
  String? _job;
  String? _avatarUrl;

  // Step 2: 興趣選擇
  List<String> _interests = [];
  String? _bio;

  // Step 3: 用餐偏好
  String _diningPreference = 'any'; // 'male', 'female', 'any', 'no_preference'
  int _minAge = 18;
  int _maxAge = 100;
  int _budgetRange = 1; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+

  // Step 4: 地區資訊
  String? _country;
  String? _city;
  String? _district;

  // Getters
  String? get name => _name;
  int? get age => _age;
  String? get gender => _gender;
  String? get job => _job;
  String? get avatarUrl => _avatarUrl;
  List<String> get interests => _interests;
  String? get bio => _bio;
  String get diningPreference => _diningPreference;
  int get minAge => _minAge;
  int get maxAge => _maxAge;
  int get budgetRange => _budgetRange;
  String? get country => _country;
  String? get city => _city;
  String? get district => _district;

  // Setters for Step 1
  void setBasicInfo({
    String? name,
    int? age,
    String? gender,
    String? job,
    String? avatarUrl,
  }) {
    _name = name;
    _age = age;
    _gender = gender;
    _job = job;
    _avatarUrl = avatarUrl;
    notifyListeners();
  }

  // Setters for Step 2
  void setInterests(List<String> interests, {String? bio}) {
    _interests = interests;
    _bio = bio;
    notifyListeners();
  }

  void setPreferences({
    required String diningPreference,
    int? minAge,
    int? maxAge,
    required int budgetRange,
  }) {
    _diningPreference = diningPreference;
    if (minAge != null) _minAge = minAge;
    if (maxAge != null) _maxAge = maxAge;
    _budgetRange = budgetRange;
    notifyListeners();
  }

  // Setters for Step 4
  void setLocation({
    required String country,
    required String city,
    required String district,
  }) {
    _country = country;
    _city = city;
    _district = district;
    notifyListeners();
  }

  // 提交所有數據到 Firestore
  Future<bool> submitOnboardingData(AuthProvider authProvider) async {
    // 驗證必填欄位
    if (_name == null || _age == null || _gender == null || _job == null) {
      return false;
    }

    if (_interests.isEmpty) {
      return false;
    }

    // location 不再是 onboarding 必填（在預約晚餐時選擇）

    // 準備更新數據
    final Map<String, dynamic> userData = {
      'name': _name,
      'age': _age,
      'gender': _gender,
      'job': _job,
      'interests': _interests,
      'diningPreference': _diningPreference,
      'minAge': _minAge,
      'maxAge': _maxAge,
      'budgetRange': _budgetRange,
    };

    // 添加可選欄位
    if (_country != null) userData['country'] = _country;
    if (_city != null) userData['city'] = _city;
    if (_district != null) userData['district'] = _district;

    if (_bio != null && _bio!.isNotEmpty) {
      userData['bio'] = _bio;
    }

    if (_avatarUrl != null) {
      userData['avatarUrl'] = _avatarUrl;
    }

    // 更新到 Firestore
    final success = await authProvider.updateUserData(userData);

    if (success) {
      // 清除臨時數據
      reset();
    }

    return success;
  }

  // 重置所有數據
  void reset() {
    _name = null;
    _age = null;
    _gender = null;
    _job = null;
    _avatarUrl = null;
    _interests = [];
    _bio = null;
    _diningPreference = 'any';
    _minAge = 18;
    _maxAge = 100;
    _budgetRange = 1;
    _country = null;
    _city = null;
    _district = null;
    notifyListeners();
  }
}



