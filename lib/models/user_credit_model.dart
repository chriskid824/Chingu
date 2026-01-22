import 'package:cloud_firestore/cloud_firestore.dart';

/// 信用交易類型
enum CreditTransactionType {
  attend, // 出席 (+10)
  noShow, // 爽約 (-20)
  completeProfile, // 完成個人資料 (+5)
  adminAdjustment, // 管理員調整
  referral, // 推薦好友
}

/// 信用等級
enum CreditLevel {
  bronze, // 0-50
  silver, // 51-100
  gold, // 101-200
  platinum, // 201+
}

/// 信用交易記錄
class CreditTransactionModel {
  final String id;
  final String userId;
  final CreditTransactionType type;
  final int amount;
  final String description;
  final DateTime createdAt;
  final String? relatedEventId;

  CreditTransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.relatedEventId,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'relatedEventId': relatedEventId,
    };
  }

  factory CreditTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return CreditTransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: CreditTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CreditTransactionType.adminAdjustment,
      ),
      amount: map['amount'] ?? 0,
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      relatedEventId: map['relatedEventId'],
    );
  }
}

/// 用戶信用模型
class UserCreditModel {
  final String userId;
  final int balance;
  final DateTime lastUpdatedAt;

  UserCreditModel({
    required this.userId,
    required this.balance,
    required this.lastUpdatedAt,
  });

  CreditLevel get level {
    if (balance > 200) return CreditLevel.platinum;
    if (balance > 100) return CreditLevel.gold;
    if (balance > 50) return CreditLevel.silver;
    return CreditLevel.bronze;
  }

  String get levelText {
    switch (level) {
      case CreditLevel.platinum: return '白金';
      case CreditLevel.gold: return '金牌';
      case CreditLevel.silver: return '銀牌';
      case CreditLevel.bronze: return '銅牌';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
    };
  }

  factory UserCreditModel.fromMap(Map<String, dynamic> map) {
    return UserCreditModel(
      userId: map['userId'] ?? '',
      balance: map['balance'] ?? 0,
      lastUpdatedAt: (map['lastUpdatedAt'] as Timestamp).toDate(),
    );
  }
}
