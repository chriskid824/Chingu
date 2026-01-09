import 'package:cloud_firestore/cloud_firestore.dart';

/// 讀取回條服務 - 處理訊息已讀狀態
class ReadReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 將訊息標記為已讀
  ///
  /// [chatRoomId] 聊天室 ID
  /// [messageId] 訊息 ID
  /// [userId] 讀取訊息的用戶 ID
  Future<void> markMessageAsRead(String chatRoomId, String messageId, String userId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'readBy': FieldValue.arrayUnion([userId]),
        // 保留 isRead 以兼容舊代碼，但主要邏輯應遷移至 readBy
        'isRead': true,
      });
    } catch (e) {
      print('標記訊息已讀失敗: $e');
    }
  }

  /// 將聊天室標記為已讀（清除未讀計數）
  ///
  /// [chatRoomId] 聊天室 ID
  /// [userId] 用戶 ID
  Future<void> markChatRoomAsRead(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('標記聊天室已讀失敗: $e');
    }
  }
}
