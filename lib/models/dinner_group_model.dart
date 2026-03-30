import 'package:cloud_firestore/cloud_firestore.dart';

/// 獨立的一場晚餐小組（5~7 人彈性一桌）
class DinnerGroupModel {
  final String id;
  final String eventId; // 每週的系統活動 ID
  
  // 參與者（5~7 人彈性）
  final List<String> participantIds; // 用戶 UID 列表
  
  // 餐廳資訊（透過 RestaurantModel 配對後寫入）
  final String? restaurantId; // 關聯到 /Restaurants/{restaurantId}
  // 以下為反正規化快取，方便前端直接顯示，不必再查 RestaurantModel
  final String? restaurantName;
  final String? restaurantAddress;
  final GeoPoint? restaurantLocation;
  final String? restaurantPhone;
  final String? restaurantImageUrl;
  
  // 群組專屬狀態 
  // 'pending' (剛分組)
  // 'info_revealed' (週二 18:00 解鎖同伴星座/產業/年齡段)
  // 'location_revealed' (週三 17:00 解鎖餐廳)
  // 'completed' (已完食)
  final String status; 
  
  // 評價狀態: 'none' (尚未開始), 'in_progress' (部分完成), 'completed' (全部完成)
  final String reviewStatus;
  
  final DateTime createdAt;
  
  // 破冰問題
  final List<String> icebreakerQuestions;

  // 同伴匿名資訊（info_revealed 後才可讀取）
  // 每個 Map: { index, zodiac, industryCategory, ageGroup, topInterests, nationality }
  final List<Map<String, dynamic>> companionPreviews;

  // 出席確認狀態 { uid: true/false }
  final Map<String, bool> attendanceConfirmed;

  DinnerGroupModel({
    required this.id,
    required this.eventId,
    required this.participantIds,
    this.restaurantId,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLocation,
    this.restaurantPhone,
    this.restaurantImageUrl,
    this.status = 'pending',
    this.reviewStatus = 'none',
    required this.createdAt,
    this.icebreakerQuestions = const [],
    this.companionPreviews = const [],
    this.attendanceConfirmed = const {},
  });

  factory DinnerGroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DinnerGroupModel.fromMap(data, doc.id);
  }

  factory DinnerGroupModel.fromMap(Map<String, dynamic> map, String id) {
    return DinnerGroupModel(
      id: id,
      eventId: map['eventId'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      restaurantId: map['restaurantId'],
      restaurantName: map['restaurantName'],
      restaurantAddress: map['restaurantAddress'],
      restaurantLocation: map['restaurantLocation'] as GeoPoint?,
      restaurantPhone: map['restaurantPhone'],
      restaurantImageUrl: map['restaurantImageUrl'],
      status: map['status'] ?? 'pending',
      reviewStatus: map['reviewStatus'] ?? 'none',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      icebreakerQuestions: List<String>.from(map['icebreakerQuestions'] ?? []),
      companionPreviews: (map['companionPreviews'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ?? [],
      attendanceConfirmed: Map<String, bool>.from(map['attendanceConfirmed'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'participantIds': participantIds,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantAddress': restaurantAddress,
      'restaurantLocation': restaurantLocation,
      'restaurantPhone': restaurantPhone,
      'restaurantImageUrl': restaurantImageUrl,
      'status': status,
      'reviewStatus': reviewStatus,
      'createdAt': Timestamp.fromDate(createdAt),
      'icebreakerQuestions': icebreakerQuestions,
      'companionPreviews': companionPreviews,
      'attendanceConfirmed': attendanceConfirmed,
    };
  }

  DinnerGroupModel copyWith({
    String? eventId,
    List<String>? participantIds,
    String? restaurantId,
    String? restaurantName,
    String? restaurantAddress,
    GeoPoint? restaurantLocation,
    String? restaurantPhone,
    String? restaurantImageUrl,
    String? status,
    String? reviewStatus,
    List<String>? icebreakerQuestions,
    List<Map<String, dynamic>>? companionPreviews,
    Map<String, bool>? attendanceConfirmed,
  }) {
    return DinnerGroupModel(
      id: id,
      eventId: eventId ?? this.eventId,
      participantIds: participantIds ?? this.participantIds,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantAddress: restaurantAddress ?? this.restaurantAddress,
      restaurantLocation: restaurantLocation ?? this.restaurantLocation,
      restaurantPhone: restaurantPhone ?? this.restaurantPhone,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      status: status ?? this.status,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      createdAt: createdAt,
      icebreakerQuestions: icebreakerQuestions ?? this.icebreakerQuestions,
      companionPreviews: companionPreviews ?? this.companionPreviews,
      attendanceConfirmed: attendanceConfirmed ?? this.attendanceConfirmed,
    );
  }

  /// 是否已解鎖餐廳資訊
  bool get isLocationRevealed => status == 'location_revealed' || status == 'completed';

  bool get isInfoRevealed => status != 'pending';

  /// 是否需要評價
  bool get isReviewPending => status == 'completed' && reviewStatus != 'completed';

  /// 評價是否已完成
  bool get isReviewCompleted => reviewStatus == 'completed';
}
