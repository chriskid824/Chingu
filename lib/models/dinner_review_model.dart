import 'package:cloud_firestore/cloud_firestore.dart';

/// 晚餐評價模型 — 用於記錄晚餐後的雙盲互評
///
/// 每位參與者對同桌的每一個人做 👍（想再聯絡）/ 👎（就到這吧）的評價。
/// 雙方都給 👍 時，系統即時建立一對一聊天室（Mutual Match）。
/// 72 小時未評價自動視為全部「跳過」。
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

  /// 評價結果：'like'（👍）| 'dislike'（👎）| 'skipped'（72hr 逾期自動跳過）
  final String result;

  /// 建立時間
  final DateTime createdAt;

  const DinnerReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.groupId,
    required this.eventId,
    required this.result,
    required this.createdAt,
  });

  factory DinnerReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    // 向後相容：舊資料用 wantToMeetAgain bool，新資料用 result string
    String result;
    if (map.containsKey('result')) {
      result = map['result'] ?? 'skipped';
    } else {
      result = (map['wantToMeetAgain'] == true) ? 'like' : 'dislike';
    }

    return DinnerReviewModel(
      id: docId,
      reviewerId: map['reviewerId'] ?? '',
      revieweeId: map['revieweeId'] ?? '',
      groupId: map['groupId'] ?? '',
      eventId: map['eventId'] ?? '',
      result: result,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'groupId': groupId,
      'eventId': eventId,
      'result': result,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  DinnerReviewModel copyWith({
    String? id,
    String? reviewerId,
    String? revieweeId,
    String? groupId,
    String? eventId,
    String? result,
    DateTime? createdAt,
  }) {
    return DinnerReviewModel(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      groupId: groupId ?? this.groupId,
      eventId: eventId ?? this.eventId,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 是否為 👍
  bool get isLike => result == 'like';

  /// 是否為 👎
  bool get isDislike => result == 'dislike';

  /// 是否為逾期跳過
  bool get isSkipped => result == 'skipped';
}
