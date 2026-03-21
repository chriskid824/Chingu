import 'package:cloud_firestore/cloud_firestore.dart';

/// 合作餐廳資料模型
/// 
/// 由營運團隊維護，系統根據 6 人飲食偏好 + 預算 + 地理位置自動配對。
/// 前端只有在 DinnerGroup.status == 'location_revealed' 時才能讀取。
class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final GeoPoint location; // 經緯度（地圖導航用）
  final String phone;
  final String? imageUrl; // 餐廳封面照
  final int budgetLevel; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+
  final int maxGroupSize; // 最大可接待人數
  final List<String> dietaryTags; // 支援的飲食類型 (e.g. 'vegan', 'halal', 'no_beef')
  final String city;
  final String district;
  final bool isActive; // 是否仍合作中
  final DateTime? lastBookedAt; // 上次被分配時間（輔助防重複）
  final DateTime createdAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.phone,
    this.imageUrl,
    required this.budgetLevel,
    this.maxGroupSize = 8,
    this.dietaryTags = const [],
    required this.city,
    required this.district,
    this.isActive = true,
    this.lastBookedAt,
    required this.createdAt,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RestaurantModel.fromMap(data, doc.id);
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map, String id) {
    return RestaurantModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      phone: map['phone'] ?? '',
      imageUrl: map['imageUrl'],
      budgetLevel: map['budgetLevel'] ?? 1,
      maxGroupSize: map['maxGroupSize'] ?? 8,
      dietaryTags: List<String>.from(map['dietaryTags'] ?? []),
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      isActive: map['isActive'] ?? true,
      lastBookedAt: map['lastBookedAt'] != null
          ? (map['lastBookedAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'phone': phone,
      'imageUrl': imageUrl,
      'budgetLevel': budgetLevel,
      'maxGroupSize': maxGroupSize,
      'dietaryTags': dietaryTags,
      'city': city,
      'district': district,
      'isActive': isActive,
      'lastBookedAt': lastBookedAt != null
          ? Timestamp.fromDate(lastBookedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RestaurantModel copyWith({
    String? name,
    String? address,
    GeoPoint? location,
    String? phone,
    String? imageUrl,
    int? budgetLevel,
    int? maxGroupSize,
    List<String>? dietaryTags,
    String? city,
    String? district,
    bool? isActive,
    DateTime? lastBookedAt,
  }) {
    return RestaurantModel(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      budgetLevel: budgetLevel ?? this.budgetLevel,
      maxGroupSize: maxGroupSize ?? this.maxGroupSize,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      city: city ?? this.city,
      district: district ?? this.district,
      isActive: isActive ?? this.isActive,
      lastBookedAt: lastBookedAt ?? this.lastBookedAt,
      createdAt: createdAt,
    );
  }

  /// 預算等級文字
  String get budgetLevelText {
    switch (budgetLevel) {
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

  /// 是否支援指定飲食類型
  bool supportsDietary(String tag) => dietaryTags.contains(tag);

  /// 是否支援全部指定飲食類型
  bool supportsAllDietary(List<String> tags) {
    if (tags.isEmpty || tags.contains('none')) return true;
    return tags.every((tag) => dietaryTags.contains(tag));
  }
}
