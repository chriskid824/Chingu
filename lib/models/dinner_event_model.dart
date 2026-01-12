import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String toStringValue() => name;

  static EventStatus fromString(String status) {
    return EventStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => EventStatus.pending,
    );
  }

  String get label {
    switch (this) {
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
}

/// 晚餐活動模型（預設6人）
class DinnerEventModel {
  final String id;
  final String creatorId;
  final DateTime dateTime;
  final int budgetRange; // 0: 300-500, 1: 500-800, 2: 800-1200, 3: 1200+
  final String city;
  final String district;
  final String? notes;
  
  // 參與者管理
  final int maxParticipants;
  final List<String> participantIds; // 用戶 UID 列表
  final Map<String, String> participantStatus; // uid -> 'pending', 'confirmed', 'declined'
  final List<String> waitingList; // 候補名單 UID 列表 (FIFO)
  final DateTime registrationDeadline; // 報名截止時間
  
  // 餐廳資訊（系統推薦後確認）
  final String? restaurantName;
  final String? restaurantAddress;
  final GeoPoint? restaurantLocation;
  final String? restaurantPhone;
  
  // 活動狀態
  final String status; // 建議使用 EventStatusEnum.toStringValue()
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
    required this.budgetRange,
    required this.city,
    required this.district,
    this.notes,
    this.maxParticipants = 6,
    required this.participantIds,
    required this.participantStatus,
    this.waitingList = const [],
    required this.registrationDeadline,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLocation,
    this.restaurantPhone,
    this.status = 'pending',
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
    // 處理舊資料可能缺少的欄位
    final eventDate = (map['dateTime'] as Timestamp).toDate();

    return DinnerEventModel(
      id: id,
      creatorId: map['creatorId'] ?? '',
      dateTime: eventDate,
      budgetRange: map['budgetRange'] ?? 1,
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      notes: map['notes'],
      maxParticipants: map['maxParticipants'] ?? 6,
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantStatus: Map<String, String>.from(map['participantStatus'] ?? {}),
      waitingList: List<String>.from(map['waitingList'] ?? []),
      registrationDeadline: map['registrationDeadline'] != null
          ? (map['registrationDeadline'] as Timestamp).toDate()
          : eventDate.subtract(const Duration(hours: 24)), // 預設截止時間為活動前24小時
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      restaurantLocation: map['restaurantLocation'] as GeoPoint?,
      restaurantPhone: map['restaurantPhone'],
      status: map['status'] ?? 'pending',
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
      'budgetRange': budgetRange,
      'city': city,
      'district': district,
      'notes': notes,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'participantStatus': participantStatus,
      'waitingList': waitingList,
      'registrationDeadline': Timestamp.fromDate(registrationDeadline),
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantLocation': restaurantLocation,
      'restaurantPhone': restaurantPhone,
      'status': status,
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
    int? budgetRange,
    String? city,
    String? district,
    String? notes,
    int? maxParticipants,
    List<String>? participantIds,
    Map<String, String>? participantStatus,
    List<String>? waitingList,
    DateTime? registrationDeadline,
    String? restaurantName,
    String? restaurantAddress,
    GeoPoint? restaurantLocation,
    String? restaurantPhone,
    String? status,
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
      budgetRange: budgetRange ?? this.budgetRange,
      city: city ?? this.city,
      district: district ?? this.district,
      notes: notes ?? this.notes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantIds: participantIds ?? this.participantIds,
      participantStatus: participantStatus ?? this.participantStatus,
      waitingList: waitingList ?? this.waitingList,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
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

  /// 獲取狀態物件
  EventStatus get eventStatus => EventStatus.fromString(status);

  /// 獲取狀態文字
  String get statusText => eventStatus.label;

  /// 檢查是否已滿員
  bool get isFull => participantIds.length >= maxParticipants;

  /// 檢查是否在候補名單中
  bool isWaitlisted(String userId) => waitingList.contains(userId);

  /// 檢查報名是否已截止
  bool get isRegistrationClosed => DateTime.now().isAfter(registrationDeadline);

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

  /// 檢查用戶是否已參加（包含確認和候補）
  bool hasUserJoined(String userId) {
    return participantIds.contains(userId) || waitingList.contains(userId);
  }

  /// 獲取平均評分
  double get averageRating {
    if (ratings == null || ratings!.isEmpty) return 0.0;
    final sum = ratings!.values.reduce((a, b) => a + b);
    return sum / ratings!.length;
  }
}
