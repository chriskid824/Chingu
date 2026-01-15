import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get toStringValue {
    return toString().split('.').last;
  }

  static EventStatus fromString(String value) {
    return EventStatus.values.firstWhere(
      (e) => e.toStringValue == value,
      orElse: () => EventStatus.pending,
    );
  }
}

/// 晚餐活動模型（固定6人）
class DinnerEventModel {
  final String id;
  final String creatorId;
  final DateTime dateTime;
  final DateTime registrationDeadline;
  final int budgetRange; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+
  final String city;
  final String district;
  final String? notes;
  
  // 參與者（固定6人）
  final List<String> participantIds; // 用戶 UID 列表
  final Map<String, String> participantStatus; // uid -> 'pending', 'confirmed', 'declined'
  
  // 等候清單
  final List<String> waitlistIds;

  // 餐廳資訊（系統推薦後確認）
  final String? restaurantName;
  final String? restaurantAddress;
  final GeoPoint? restaurantLocation;
  final String? restaurantPhone;
  
  // 活動狀態
  final EventStatus status;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  
  // 破冰問題
  final List<String> icebreakerQuestions;
  
  // 評價（活動結束後）
  final Map<String, double>? ratings; // uid -> rating (1-5)
  final Map<String, String>? reviews; // uid -> review text

  DinnerEventModel({
    required this.id,
    required this.creatorId,
    required this.dateTime,
    required this.registrationDeadline,
    required this.budgetRange,
    required this.city,
    required this.district,
    this.notes,
    required this.participantIds,
    required this.participantStatus,
    this.waitlistIds = const [],
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLocation,
    this.restaurantPhone,
    this.status = EventStatus.pending,
    required this.createdAt,
    this.confirmedAt,
    this.completedAt,
    this.icebreakerQuestions = const [],
    this.ratings,
    this.reviews,
  });

  /// 從 Firestore 文檔創建 DinnerEventModel
  factory DinnerEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DinnerEventModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 DinnerEventModel
  factory DinnerEventModel.fromMap(Map<String, dynamic> map, String id) {
    return DinnerEventModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      registrationDeadline: map['registrationDeadline'] != null
          ? (map['registrationDeadline'] as Timestamp).toDate()
          : (map['dateTime'] as Timestamp).toDate().subtract(const Duration(hours: 24)), // Default fallback
      budgetRange: map['budgetRange'] ?? 1,
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      notes: map['notes'],
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantStatus: Map<String, String>.from(map['participantStatus'] ?? {}),
      waitlistIds: List<String>.from(map['waitlistIds'] ?? []),
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      restaurantLocation: map['restaurantLocation'] as GeoPoint?,
      restaurantPhone: map['restaurantPhone'],
      status: EventStatus.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      confirmedAt: map['confirmedAt'] != null 
          ? (map['confirmedAt'] as Timestamp).toDate() 
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      icebreakerQuestions: List<String>.from(map['icebreakerQuestions'] ?? []),
      ratings: map['ratings'] != null 
          ? Map<String, double>.from(map['ratings']) 
          : null,
      reviews: map['reviews'] != null 
          ? Map<String, String>.from(map['reviews']) 
          : null,
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'creatorId': creatorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'budgetRange': budgetRange,
      'city': city,
      'district': district,
      'notes': notes,
      'participantIds': participantIds,
      'participantStatus': participantStatus,
      'waitlistIds': waitlistIds,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantLocation': restaurantLocation,
      'restaurantPhone': restaurantPhone,
      'status': status.toStringValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'icebreakerQuestions': icebreakerQuestions,
      'ratings': ratings,
      'reviews': reviews,
    };
  }

  /// 複製並更新部分欄位
  DinnerEventModel copyWith({
    DateTime? dateTime,
    DateTime? registrationDeadline,
    int? budgetRange,
    String? city,
    String? district,
    String? notes,
    List<String>? participantIds,
    Map<String, String>? participantStatus,
    List<String>? waitlistIds,
    String? restaurantName,
    String? restaurantAddress,
    GeoPoint? restaurantLocation,
    String? restaurantPhone,
    EventStatus? status,
    DateTime? confirmedAt,
    DateTime? completedAt,
    List<String>? icebreakerQuestions,
    Map<String, double>? ratings,
    Map<String, String>? reviews,
  }) {
    return DinnerEventModel(
      id: id,
      creatorId: creatorId,
      dateTime: dateTime ?? this.dateTime,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      budgetRange: budgetRange ?? this.budgetRange,
      city: city ?? this.city,
      district: district ?? this.district,
      notes: notes ?? this.notes,
      participantIds: participantIds ?? this.participantIds,
      participantStatus: participantStatus ?? this.participantStatus,
      waitlistIds: waitlistIds ?? this.waitlistIds,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      restaurantPhone: restaurantPhone ?? this.restaurantPhone,
      status: status ?? this.status,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      icebreakerQuestions: icebreakerQuestions ?? this.icebreakerQuestions,
      ratings: ratings ?? this.ratings,
      reviews: reviews ?? this.reviews,
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

  /// 獲取狀態文字
  String get statusText {
    switch (status) {
      case EventStatus.pending:
        return '等待配對';
      case EventStatus.confirmed:
        return '已確認';
      case EventStatus.completed:
        return '已完成';
      case EventStatus.cancelled:
        return '已取消';
    }
  }

  /// 檢查是否已滿6人
  bool get isFull => participantIds.length >= 6;

  /// 獲取已確認人數
  int get confirmedCount {
    return participantStatus.values
        .where((status) => status == 'confirmed')
        .length;
  }

  /// 檢查用戶是否已確認
  bool isUserConfirmed(String userId) {
    return participantStatus[userId] == 'confirmed';
  }

  /// 獲取平均評分
  double get averageRating {
    if (ratings == null || ratings!.isEmpty) return 0.0;
    final sum = ratings!.values.reduce((a, b) => a + b);
    return sum / ratings!.length;
  }
}
