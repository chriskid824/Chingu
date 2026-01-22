import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_credit_model.dart';
import 'package:chingu/models/user_model.dart';

class CreditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _creditsCollection => _firestore.collection('user_credits');
  CollectionReference get _transactionsCollection => _firestore.collection('credit_transactions');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// 獲取用戶信用資料
  Future<UserCreditModel> getUserCredit(String userId) async {
    try {
      final doc = await _creditsCollection.doc(userId).get();
      if (!doc.exists) {
        // 如果不存在，創建初始資料
        final initialCredit = UserCreditModel(
          userId: userId,
          balance: 50, // 初始 50 分
          lastUpdatedAt: DateTime.now(),
        );
        await _creditsCollection.doc(userId).set(initialCredit.toMap());
        return initialCredit;
      }
      return UserCreditModel.fromMap(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('獲取信用資料失敗: $e');
    }
  }

  /// 增加信用點數
  Future<void> addCredit({
    required String userId,
    required int amount,
    required CreditTransactionType type,
    required String description,
    String? relatedEventId,
  }) async {
    if (amount <= 0) throw Exception('增加點數必須大於 0');
    await _processTransaction(userId, amount, type, description, relatedEventId);
  }

  /// 扣除信用點數
  Future<void> deductCredit({
    required String userId,
    required int amount,
    required CreditTransactionType type,
    required String description,
    String? relatedEventId,
  }) async {
    if (amount <= 0) throw Exception('扣除點數必須大於 0');
    await _processTransaction(userId, -amount, type, description, relatedEventId);
  }

  /// 處理交易並更新餘額
  Future<void> _processTransaction(
    String userId,
    int changeAmount,
    CreditTransactionType type,
    String description,
    String? relatedEventId,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final creditRef = _creditsCollection.doc(userId);
        final creditDoc = await transaction.get(creditRef);

        int currentBalance = 50; // Default
        if (creditDoc.exists) {
          final data = creditDoc.data() as Map<String, dynamic>;
          currentBalance = data['balance'] ?? 50;
        }

        final newBalance = currentBalance + changeAmount;

        // Update Credit Balance
        transaction.set(creditRef, {
          'userId': userId,
          'balance': newBalance,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Add Transaction Record
        final transactionRef = _transactionsCollection.doc();
        final transactionModel = CreditTransactionModel(
          id: transactionRef.id,
          userId: userId,
          type: type,
          amount: changeAmount,
          description: description,
          createdAt: DateTime.now(),
          relatedEventId: relatedEventId,
        );
        transaction.set(transactionRef, transactionModel.toMap());

        // Update User Model if needed (e.g. no_show_count)
        if (type == CreditTransactionType.noShow) {
             final userRef = _usersCollection.doc(userId);
             transaction.update(userRef, {
                 'noShowCount': FieldValue.increment(1),
             });
        }
      });
    } catch (e) {
      throw Exception('處理信用交易失敗: $e');
    }
  }

  /// 獲取交易歷史
  Future<List<CreditTransactionModel>> getTransactionHistory(String userId) async {
    try {
      final snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => CreditTransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('獲取交易歷史失敗: $e');
    }
  }
}
