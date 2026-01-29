import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/firestore_service.dart';

/// 用戶統計資料模型
class UserStats {
  final int matchCount;
  final int eventCount;
  final int chatCount;

  UserStats({
    required this.matchCount,
    required this.eventCount,
    required this.chatCount,
  });
}

/// 統計服務 - 聚合用戶各項使用數據
class StatsService {
  final FirebaseFirestore _firestore;
  final FirestoreService _firestoreService;

  StatsService({
    FirebaseFirestore? firestore,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// 獲取用戶統計儀表板數據
  ///
  /// [userId] 用戶 ID
  Future<UserStats> getUserStats(String userId) async {
    try {
      // 1. 獲取用戶資料 (配對次數)
      final user = await _firestoreService.getUser(userId);
      if (user == null) throw Exception('用戶不存在');

      // 使用 UserModel 中的 totalMatches，因為 MatchingService 有維護此欄位
      final matchCount = user.totalMatches;

      // 2. 獲取聊天活躍度 (活躍聊天室數量)
      // 使用 count() 聚合查詢
      final chatsQuery = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userId)
          .count()
          .get();

      final chatCount = chatsQuery.count ?? 0;

      // 3. 獲取活動參與數 (已結束的活動)
      // 由於可能缺少複合索引 (participantIds + dateTime)，
      // 我們先獲取該用戶參與的所有活動，然後在內存中過濾已過期的
      // 這也避免了查詢失敗
      final eventsSnapshot = await _firestore
          .collection('dinner_events')
          .where('participantIds', arrayContains: userId)
          .get();

      final now = DateTime.now();
      int eventCount = 0;

      for (var doc in eventsSnapshot.docs) {
        final data = doc.data();
        if (data['dateTime'] != null) {
          final DateTime eventDate = (data['dateTime'] as Timestamp).toDate();
          // 只計算已過去的活動 (且不計算已取消的?)
          // 假設只要不是 cancelled 且時間已過就算參與
          final status = data['status'] as String? ?? 'pending';
          if (eventDate.isBefore(now) && status != 'cancelled') {
            eventCount++;
          }
        }
      }

      return UserStats(
        matchCount: matchCount,
        eventCount: eventCount,
        chatCount: chatCount,
      );
    } catch (e) {
      print('StatsService.getUserStats 錯誤: $e');
      // 出錯時返回 0 避免頁面崩潰
      return UserStats(matchCount: 0, eventCount: 0, chatCount: 0);
    }
  }
}
