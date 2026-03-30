import 'package:cloud_firestore/cloud_firestore.dart';

/// 系統主辦的每週大活動（無人數上限，報名後系統再切分 DinnerGroup）
class DinnerEventModel {
  final String id; // e.g. "dinner_2026_03_25"
  final DateTime eventDate; // 活動正式時間（週四晚間）
  final DateTime signupDeadline; // 報名截止時間（週二中午 12:00）
  
  // 狀態: 'open' (開放報名), 'matching' (配對中/已截止), 'revealed' (已解鎖資訊), 'completed' (已結束)
  final String status;
  
  final String city; // 本週活動所在城市
  final List<String> signedUpUsers; // 報名該場次的所有用戶UID
  
  final DateTime createdAt;

  DinnerEventModel({
    required this.id,
    required this.eventDate,
    required this.signupDeadline,
    this.status = 'open',
    this.city = '',
    this.signedUpUsers = const [],
    required this.createdAt,
  });

  factory DinnerEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DinnerEventModel.fromMap(data, doc.id);
  }

  factory DinnerEventModel.fromMap(Map<String, dynamic> map, String id) {
    return DinnerEventModel(
      id: id,
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      signupDeadline: (map['signupDeadline'] as Timestamp).toDate(),
      status: map['status'] ?? 'open',
      city: map['city'] ?? '',
      signedUpUsers: List<String>.from(map['signedUpUsers'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventDate': Timestamp.fromDate(eventDate),
      'signupDeadline': Timestamp.fromDate(signupDeadline),
      'status': status,
      'city': city,
      'signedUpUsers': signedUpUsers,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DinnerEventModel copyWith({
    DateTime? eventDate,
    DateTime? signupDeadline,
    String? status,
    String? city,
    List<String>? signedUpUsers,
  }) {
    return DinnerEventModel(
      id: id,
      eventDate: eventDate ?? this.eventDate,
      signupDeadline: signupDeadline ?? this.signupDeadline,
      status: status ?? this.status,
      city: city ?? this.city,
      signedUpUsers: signedUpUsers ?? this.signedUpUsers,
      createdAt: createdAt,
    );
  }
}
