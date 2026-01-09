import 'package:cloud_firestore/cloud_firestore.dart';

/// 訊息編輯服務 - 處理已發送訊息的編輯功能
class MessageEditService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 編輯訊息
  ///
  /// [messageId] 要編輯的訊息 ID
  /// [newText] 新的訊息內容
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    try {
      if (newText.trim().isEmpty) {
        throw Exception('訊息內容不能為空');
      }

      await _firestore.collection('messages').doc(messageId).update({
        'text': newText.trim(),
        'message': newText.trim(),
        'isEdited': true,
        'editedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('編輯訊息失敗: $e');
    }
  }
}
