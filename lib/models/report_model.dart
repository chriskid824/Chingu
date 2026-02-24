import 'package:cloud_firestore/cloud_firestore.dart';

/// 舉報原因類別
enum ReportReason {
  spam,        // 垃圾訊息
  harassment,  // 騷擾
  inappropriate, // 不當內容
  fake,        // 假帳號
  other,       // 其他
}

/// 舉報原因的顯示文字
extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return '垃圾訊息';
      case ReportReason.harassment:
        return '騷擾行為';
      case ReportReason.inappropriate:
        return '不當內容';
      case ReportReason.fake:
        return '假帳號/詐騙';
      case ReportReason.other:
        return '其他原因';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportReason.other,
    );
  }
}

/// 舉報狀態
enum ReportStatus {
  pending,  // 待審核
  reviewed, // 已審核
  resolved, // 已處理
}

extension ReportStatusExtension on ReportStatus {
  String get value {
    return toString().split('.').last;
  }

  static ReportStatus fromString(String value) {
    return ReportStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReportStatus.pending,
    );
  }
}

/// 舉報資料模型
class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String? description;
  final ReportStatus status;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    this.description,
    this.status = ReportStatus.pending,
    required this.createdAt,
  });

  /// 從 Firestore 文檔創建
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建
  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: ReportReasonExtension.fromString(map['reason'] ?? 'other'),
      description: map['description'],
      status: ReportStatusExtension.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.value,
      'description': description,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
