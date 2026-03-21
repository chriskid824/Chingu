import 'package:cloud_firestore/cloud_firestore.dart';

/// 晚餐評價模型 — 用於記錄晚餐後的互評
///
/// 每位參與者可以對同桌的其他人做「想再見面 / 不了」的評價。
/// 雙方都選「想再見面」時，系統自動建立聊天室（Mutual Match）。
class DinnerReviewModel {
  final String id;
  
  /// 評價者 UID
  final String reviewerId;
  
  /// 被評價者 UID
  final String revieweeId;
  
  /// 所屬晚餐群組 ID
  final String groupId;
  
  /// 所屬活動 ID
  final String eventId;
  
  /// 是否想再見面
  final bool wantToMeetAgain;

  /// 體驗評分（1-5，emoji 滑桿）
  final int? experienceRating;

  /// 體驗亮點（多選）
  final List<String> experienceHighlights;

  /// 下次偏好（選填，≥第 3 次才顯示）
  final String? preferenceForNext;
  
  /// 建立時間
  final DateTime createdAt;

  const DinnerReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.groupId,
    required this.eventId,
    required this.wantToMeetAgain,
    this.experienceRating,
    this.experienceHighlights = const [],
    this.preferenceForNext,
    required this.createdAt,
  });

  factory DinnerReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return DinnerReviewModel(
      id: docId,
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      groupId: map['groupId'] ?? '',
      eventId: map['eventId'] ?? '',
      wantToMeetAgain: map['wantToMeetAgain'] ?? false,
      experienceRating: map['experienceRating'] as int?,
      experienceHighlights: List<String>.from(map['experienceHighlights'] ?? []),
      preferenceForNext: map['preferenceForNext'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'groupId': groupId,
      'eventId': eventId,
      'wantToMeetAgain': wantToMeetAgain,
      if (experienceRating != null) 'experienceRating': experienceRating,
      if (experienceHighlights.isNotEmpty) 'experienceHighlights': experienceHighlights,
      if (preferenceForNext != null) 'preferenceForNext': preferenceForNext,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DinnerReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? revieweeId,
    String? groupId,
    String? eventId,
    bool? wantToMeetAgain,
    int? experienceRating,
    List<String>? experienceHighlights,
    String? preferenceForNext,
    DateTime? createdAt,
  }) {
    return DinnerReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      wantToMeetAgain: wantToMeetAgain ?? this.wantToMeetAgain,
      experienceRating: experienceRating ?? this.experienceRating,
      experienceHighlights: experienceHighlights ?? this.experienceHighlights,
      preferenceForNext: preferenceForNext ?? this.preferenceForNext,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
