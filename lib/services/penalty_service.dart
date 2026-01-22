import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/credit_service.dart';
import 'package:chingu/models/user_credit_model.dart';

class PenaltyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CreditService _creditService = CreditService();

  /// 檢查爽約並執行懲罰
  ///
  /// 規則: 活動後48小時未確認出席且未取消 = -20點
  /// 這通常由 Cloud Scheduler 觸發，但在此模擬為客戶端可調用的檢查（例如在管理員後台或定期觸發）
  Future<void> checkAndApplyPenalties() async {
    final now = DateTime.now();
    final checkTime = now.subtract(const Duration(hours: 48));

    // 找出 48 小時前結束且未結算的活動
    // 這裡簡化邏輯：查詢所有 'confirmed' 且時間早於 checkTime 的活動
    try {
      final snapshot = await _firestore.collection('dinner_events')
          .where('status', isEqualTo: 'confirmed')
          .where('dateTime', isLessThan: checkTime)
          .get();

      for (var doc in snapshot.docs) {
        await _processEventPenalty(doc);
      }
    } catch (e) {
      print('Penalty check failed: $e');
    }
  }

  Future<void> _processEventPenalty(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final eventId = doc.id;
    final participantIds = List<String>.from(data['participantIds'] ?? []);

    // 假設我們有一個 'attendanceConfirmed' 字段在活動中記錄誰確認了
    // 或是查詢 transactions

    for (var userId in participantIds) {
      // 檢查該用戶是否有針對此活動的出席記錄
      final hasAttended = await _hasUserAttended(userId, eventId);

      if (!hasAttended) {
        // 執行懲罰
        try {
          // 檢查是否已經懲罰過 (避免重複扣分)
          final hasPenalized = await _hasBeenPenalized(userId, eventId);
          if (!hasPenalized) {
             await _creditService.deductCredit(
               userId: userId,
               amount: 20,
               type: CreditTransactionType.noShow,
               description: '活動爽約懲罰',
               relatedEventId: eventId,
             );
          }
        } catch (e) {
          print('Failed to penalize user $userId: $e');
        }
      }
    }

    // 更新活動狀態為 completed (settled)
    await _firestore.collection('dinner_events').doc(eventId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> _hasUserAttended(String userId, String eventId) async {
    final snapshot = await _firestore.collection('credit_transactions')
        .where('userId', isEqualTo: userId)
        .where('relatedEventId', isEqualTo: eventId)
        .where('type', isEqualTo: CreditTransactionType.attend.name)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Future<bool> _hasBeenPenalized(String userId, String eventId) async {
    final snapshot = await _firestore.collection('credit_transactions')
        .where('userId', isEqualTo: userId)
        .where('relatedEventId', isEqualTo: eventId)
        .where('type', isEqualTo: CreditTransactionType.noShow.name)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
