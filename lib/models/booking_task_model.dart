import 'package:cloud_firestore/cloud_firestore.dart';

/// 訂位工單模型
///
/// 配對完成後，系統自動產出工單。
/// 營運人員在後台看到工單 → 致電訂位 → 回填確認 → 觸發推播。
class BookingTaskModel {
  final String id;
  final String groupId; // 對應的 DinnerGroup ID
  final String eventId; // 對應的 DinnerEvent ID
  final List<String> candidateRestaurantIds; // Top 3 候選餐廳 ID（優先→備選→兜底）
  final String? confirmedRestaurantId; // 最終確認的餐廳 ID
  
  // 'pending' | 'in_progress' | 'confirmed' | 'failed'
  final String status;
  
  final String? assignedTo; // 負責營運人員 UID
  final String? notes; // 備註（失敗原因、特殊需求等）
  final DateTime createdAt;
  final DateTime? confirmedAt;

  BookingTaskModel({
    required this.id,
    required this.groupId,
    required this.eventId,
    required this.candidateRestaurantIds,
    this.confirmedRestaurantId,
    this.status = 'pending',
    this.assignedTo,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
  });

  factory BookingTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingTaskModel.fromMap(data, doc.id);
  }

  factory BookingTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return BookingTaskModel(
      id: id,
      groupId: map['groupId'] ?? '',
      eventId: map['eventId'] ?? '',
      candidateRestaurantIds: List<String>.from(map['candidateRestaurantIds'] ?? []),
      confirmedRestaurantId: map['confirmedRestaurantId'],
      status: map['status'] ?? 'pending',
      assignedTo: map['assignedTo'],
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'eventId': eventId,
      'candidateRestaurantIds': candidateRestaurantIds,
      'confirmedRestaurantId': confirmedRestaurantId,
      'status': status,
      'assignedTo': assignedTo,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null
          ? Timestamp.fromDate(confirmedAt!)
          : null,
    };
  }

  BookingTaskModel copyWith({
    String? groupId,
    String? eventId,
    List<String>? candidateRestaurantIds,
    String? confirmedRestaurantId,
    String? status,
    String? assignedTo,
    String? notes,
    DateTime? confirmedAt,
  }) {
    return BookingTaskModel(
      id: id,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      candidateRestaurantIds: candidateRestaurantIds ?? this.candidateRestaurantIds,
      confirmedRestaurantId: confirmedRestaurantId ?? this.confirmedRestaurantId,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  /// 是否已確認訂位
  bool get isConfirmed => status == 'confirmed';

  /// 是否失敗
  bool get isFailed => status == 'failed';

  /// 是否還在處理中
  bool get isPending => status == 'pending' || status == 'in_progress';

  /// 狀態文字
  String get statusText {
    switch (status) {
      case 'pending':
        return '待處理';
      case 'in_progress':
        return '處理中';
      case 'confirmed':
        return '已確認';
      case 'failed':
        return '訂位失敗';
      default:
        return '未知';
    }
  }
}
