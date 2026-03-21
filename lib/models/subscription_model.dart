import 'package:cloud_firestore/cloud_firestore.dart';

/// 訂閱方案類型
enum SubscriptionPlan {
  free,      // 免費體驗（前 3 次）
  single,    // 單次票 NT$149
  monthly,   // 月票 NT$399
  quarterly, // 季票 NT$999
}

/// 訂閱狀態模型
class SubscriptionModel {
  final String userId;
  final SubscriptionPlan plan;
  final int freeTrialsRemaining; // 剩餘免費次數（初始 3）
  final int singleTickets;       // 剩餘單次票數量
  final DateTime? expiresAt;     // 訂閱到期時間
  final DateTime? lastPurchaseAt;
  final String? revenueCatId;    // RevenueCat 訂閱 ID

  const SubscriptionModel({
    required this.userId,
    this.plan = SubscriptionPlan.free,
    this.freeTrialsRemaining = 3,
    this.singleTickets = 0,
    this.expiresAt,
    this.lastPurchaseAt,
    this.revenueCatId,
  });

  /// 是否可以報名（有免費次數、有單次票、或有有效訂閱）
  bool get canBook {
    if (freeTrialsRemaining > 0) return true;
    if (singleTickets > 0) return true;
    if (plan == SubscriptionPlan.monthly || plan == SubscriptionPlan.quarterly) {
      return expiresAt != null && expiresAt!.isAfter(DateTime.now());
    }
    return false;
  }

  /// 是否為付費用戶
  bool get isPremium =>
      plan == SubscriptionPlan.monthly ||
      plan == SubscriptionPlan.quarterly;

  /// 是否仍在免費體驗期
  bool get isFreeTrial => freeTrialsRemaining > 0;

  /// 顯示用的方案名稱
  String get planDisplayName {
    switch (plan) {
      case SubscriptionPlan.free:
        return '免費體驗';
      case SubscriptionPlan.single:
        return '單次票';
      case SubscriptionPlan.monthly:
        return '月票';
      case SubscriptionPlan.quarterly:
        return '季票';
    }
  }

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String uid) {
    return SubscriptionModel(
      userId: uid,
      plan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == (map['plan'] ?? 'free'),
        orElse: () => SubscriptionPlan.free,
      ),
      freeTrialsRemaining: map['freeTrialsRemaining'] ?? 3,
      singleTickets: map['singleTickets'] ?? 0,
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate(),
      lastPurchaseAt: (map['lastPurchaseAt'] as Timestamp?)?.toDate(),
      revenueCatId: map['revenueCatId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.name,
      'freeTrialsRemaining': freeTrialsRemaining,
      'singleTickets': singleTickets,
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
      if (lastPurchaseAt != null)
        'lastPurchaseAt': Timestamp.fromDate(lastPurchaseAt!),
      if (revenueCatId != null) 'revenueCatId': revenueCatId,
    };
  }

  SubscriptionModel copyWith({
    String? userId,
    SubscriptionPlan? plan,
    int? freeTrialsRemaining,
    int? singleTickets,
    DateTime? expiresAt,
    DateTime? lastPurchaseAt,
    String? revenueCatId,
  }) {
    return SubscriptionModel(
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      freeTrialsRemaining: freeTrialsRemaining ?? this.freeTrialsRemaining,
      singleTickets: singleTickets ?? this.singleTickets,
      expiresAt: expiresAt ?? this.expiresAt,
      lastPurchaseAt: lastPurchaseAt ?? this.lastPurchaseAt,
      revenueCatId: revenueCatId ?? this.revenueCatId,
    );
  }
}
