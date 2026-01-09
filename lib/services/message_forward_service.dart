import 'package:chingu/models/chat_message_model.dart';
import 'package:chingu/services/chat_service.dart';

/// 訊息轉發服務
class MessageForwardService {
  final ChatService _chatService = ChatService();

  /// 轉發訊息到多個聊天室
  ///
  /// [originalMessage] 要轉發的原始訊息
  /// [targetChatRoomIds] 目標聊天室 ID 列表
  /// [currentUserId] 當前用戶 ID (轉發者)
  /// [currentUserName] 當前用戶名稱
  /// [currentUserAvatarUrl] 當前用戶頭像 URL
  Future<void> forwardMessage({
    required ChatMessageModel originalMessage,
    required List<String> targetChatRoomIds,
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatarUrl,
  }) async {
    try {
      // 確定原始發送者資訊
      // 如果訊息已經被轉發過，則保留最初的發送者
      final originalSenderId = originalMessage.isForwarded
          ? originalMessage.originalSenderId
          : originalMessage.senderId;

      final originalSenderName = originalMessage.isForwarded
          ? originalMessage.originalSenderName
          : originalMessage.senderName;

      // 遍歷目標聊天室並發送
      for (final chatRoomId in targetChatRoomIds) {
        await _chatService.sendMessage(
          chatRoomId: chatRoomId,
          senderId: currentUserId,
          senderName: currentUserName,
          senderAvatarUrl: currentUserAvatarUrl,
          message: originalMessage.message,
          type: originalMessage.type,
          isForwarded: true,
          originalSenderId: originalSenderId,
          originalSenderName: originalSenderName,
        );
      }
    } catch (e) {
      throw Exception('轉發訊息失敗: $e');
    }
  }
}
