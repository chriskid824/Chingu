import 'package:cloud_firestore/cloud_firestore.dart';

/// 舉報模型
class ReportModel {
  final String? id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'
  final String type; // 'user_report'

  ReportModel({
    this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    required this.createdAt,
    this.status = 'pending',
    this.type = 'user_report',
  });

  /// 從 Firestore 文檔創建 ReportModel
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 ReportModel
  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      type: map['type'] ?? 'user_report',
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'type': type,
    };
  }

  /// 複製並更新部分欄位
  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    String? reason,
    String? description,
    DateTime? createdAt,
    String? status,
    String? type,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
}
