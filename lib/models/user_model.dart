import 'package:cloud_firestore/cloud_firestore.dart';

/// 用戶資料模型
class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender; // 'male', 'female', 'non_binary', 'undisclosed'
  final String job;
  final List<String> interests;
  final String country;
  final String city;
  final String district;
  final String? bio;
  final String? avatarUrl;
  
  // 用餐偏好
  final String diningPreference; // 'male', 'female', 'any', 'no_preference'
  final int minAge;
  final int maxAge;
  final int budgetRange; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+
  final List<String> dietaryPreferences; // e.g., 'none', 'vegetarian', 'vegan', 'no_beef', 'no_pork', 'halal'
  
  // 系統欄位
  final bool isActive;
  final DateTime createdAt;
  final DateTime lastLogin;
  final GeoPoint? locationGeo;
  final String subscription; // 'free' or 'premium'
  
  // 統計資料
  final int totalDinners;
  final int totalMatches;
  final double averageRating;

  // 2FA
  final bool isTwoFactorEnabled;
  final String twoFactorMethod; // 'email', 'sms'
  final String? phoneNumber;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.gender,
    required this.job,
    required this.interests,
    required this.country,
    required this.city,
    required this.district,
    this.bio,
    this.avatarUrl,
    required this.diningPreference,
    required this.minAge,
    required this.maxAge,
    required this.budgetRange,
    this.dietaryPreferences = const ['none'],
    this.isActive = true,
    required this.createdAt,
    required this.lastLogin,
    this.locationGeo,
    this.subscription = 'free',
    this.totalDinners = 0,
    this.totalMatches = 0,
    this.averageRating = 0.0,
    this.isTwoFactorEnabled = false,
    this.twoFactorMethod = 'email',
    this.phoneNumber,
  });

  /// 從 Firestore 文檔創建 UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      gender: map['gender'] ?? 'male',
      job: map['job'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      country: map['country'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      bio: map['bio'],
      avatarUrl: map['avatarUrl'],
      diningPreference: map['diningPreference'] ?? map['preferredMatchType'] ?? 'any',
      minAge: map['minAge'] ?? 18,
      maxAge: map['maxAge'] ?? 60,
      budgetRange: map['budgetRange'] ?? 1,
      dietaryPreferences: List<String>.from(map['dietaryPreferences'] ?? ['none']),
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: (map['lastLogin'] as Timestamp).toDate(),
      locationGeo: map['locationGeo'] as GeoPoint?,
      subscription: map['subscription'] ?? 'free',
      totalDinners: map['totalDinners'] ?? 0,
      totalMatches: map['totalMatches'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      isTwoFactorEnabled: map['isTwoFactorEnabled'] ?? false,
      twoFactorMethod: map['twoFactorMethod'] ?? 'email',
      phoneNumber: map['phoneNumber'],
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'job': job,
      'interests': interests,
      'country': country,
      'city': city,
      'district': district,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'diningPreference': diningPreference,
      'minAge': minAge,
      'maxAge': maxAge,
      'budgetRange': budgetRange,
      'dietaryPreferences': dietaryPreferences,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'locationGeo': locationGeo,
      'subscription': subscription,
      'totalDinners': totalDinners,
      'totalMatches': totalMatches,
      'averageRating': averageRating,
      'isTwoFactorEnabled': isTwoFactorEnabled,
      'twoFactorMethod': twoFactorMethod,
      'phoneNumber': phoneNumber,
    };
  }

  /// 複製並更新部分欄位
  UserModel copyWith({
    String? name,
    String? email,
    int? age,
    String? gender,
    String? job,
    List<String>? interests,
    String? country,
    String? city,
    String? district,
    String? bio,
    String? avatarUrl,
    String? diningPreference,
    int? minAge,
    int? maxAge,
    int? budgetRange,
    List<String>? dietaryPreferences,
    bool? isActive,
    DateTime? lastLogin,
    GeoPoint? locationGeo,
    String? subscription,
    int? totalDinners,
    int? totalMatches,
    double? averageRating,
    bool? isTwoFactorEnabled,
    String? twoFactorMethod,
    String? phoneNumber,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      job: job ?? this.job,
      interests: interests ?? this.interests,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      diningPreference: diningPreference ?? this.diningPreference,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      budgetRange: budgetRange ?? this.budgetRange,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      locationGeo: locationGeo ?? this.locationGeo,
      subscription: subscription ?? this.subscription,
      totalDinners: totalDinners ?? this.totalDinners,
      totalMatches: totalMatches ?? this.totalMatches,
      averageRating: averageRating ?? this.averageRating,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      twoFactorMethod: twoFactorMethod ?? this.twoFactorMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }



  /// 獲取性別文字
  String get genderText {
    switch (gender) {
      case 'male':
        return '男性';
      case 'female':
        return '女性';
      case 'non_binary':
        return '非二元';
      case 'undisclosed':
        return '不公開';
      default:
        return '不公開';
    }
  }

  /// 獲取用餐偏好文字
  String get diningPreferenceText {
    switch (diningPreference) {
      case 'male':
        return '男性為主';
      case 'female':
        return '女性為主';
      case 'any':
        return '都喜歡';
      case 'no_preference':
        return '隨緣';
      default:
        return '隨緣';
    }
  }

  /// 個人資料是否填寫完整（用於 Onboarding 流程判斷）
  bool get isProfileComplete {
    return name.isNotEmpty &&
        age > 0 &&
        gender.isNotEmpty &&
        job.isNotEmpty &&
        interests.isNotEmpty &&
        city.isNotEmpty;
  }
}
