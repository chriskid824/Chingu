import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/notification_settings_model.dart';

/// 用戶資料模型
class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String gender; // 'male' or 'female'
  final String job;
  final List<String> interests;
  final String country;
  final String city;
  final String district;
  final String? bio;
  final String? avatarUrl;
  
  // 配對偏好
  final String preferredMatchType; // 'opposite', 'same', 'any'
  final int minAge;
  final int maxAge;
  final int budgetRange; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+
  
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

  // 通知設定
  final NotificationSettingsModel? notificationSettings;

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
    required this.preferredMatchType,
    required this.minAge,
    required this.maxAge,
    required this.budgetRange,
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
    this.notificationSettings,
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
      preferredMatchType: map['preferredMatchType'] ?? 'any',
      minAge: map['minAge'] ?? 18,
      maxAge: map['maxAge'] ?? 60,
      budgetRange: map['budgetRange'] ?? 1,
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
      notificationSettings: map['notificationSettings'] != null
          ? NotificationSettingsModel.fromMap(map['notificationSettings'])
          : null,
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
      'preferredMatchType': preferredMatchType,
      'minAge': minAge,
      'maxAge': maxAge,
      'budgetRange': budgetRange,
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
      'notificationSettings': notificationSettings?.toMap(),
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
    String? preferredMatchType,
    int? minAge,
    int? maxAge,
    int? budgetRange,
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
    NotificationSettingsModel? notificationSettings,
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
      preferredMatchType: preferredMatchType ?? this.preferredMatchType,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      budgetRange: budgetRange ?? this.budgetRange,
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
      notificationSettings: notificationSettings ?? this.notificationSettings,
    );
  }

  /// 獲取預算範圍文字
  String get budgetRangeText {
    switch (budgetRange) {
      case 0:
        return 'NT\$ 300-500';
      case 1:
        return 'NT\$ 500-800';
      case 2:
        return 'NT\$ 800-1200';
      case 3:
        return 'NT\$ 1200+';
      default:
        return 'NT\$ 500-800';
    }
  }

  /// 獲取性別文字
  String get genderText {
    return gender == 'male' ? '男性' : '女性';
  }

  /// 獲取配對類型文字
  String get preferredMatchTypeText {
    switch (preferredMatchType) {
      case 'opposite':
        return '異性配對';
      case 'same':
        return '同性配對';
      case 'any':
        return '不限';
      default:
        return '不限';
    }
  }
}
