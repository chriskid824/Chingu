import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/models/user_model.dart';

/// 聊天服務 - 處理聊天室的創建與管理
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 聊天室集合引用
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');

  /// 訊息集合引用 (Root collection, as per legacy design)
  CollectionReference get _messagesCollection => _firestore.collection('messages');

  /// 創建或獲取現有聊天室
  /// 
  /// 如果兩人之間已存在聊天室，則返回現有 ID。
  /// 否則創建一個新的聊天室並返回新 ID。
  ///
  /// [user1Id] 用戶 1 ID (發起者)
  /// [user2Id] 用戶 2 ID (接收者)
  ///
  /// 返回聊天室文檔 ID
  Future<String> createChatRoom(String user1Id, String user2Id) async {
    try {
      // 1. 檢查是否已存在聊天室
      // 由於 Firestore 查詢限制，我們可能需要兩次查詢或在客戶端過濾
      // 這裡我們假設每個配對只有一個聊天室
      
      // 查詢 user1 的所有聊天室
      final query = await _chatRoomsCollection
          .where('participantIds', arrayContains: user1Id)
          .get();
          
      for (var doc in query.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participantIds'] ?? []);
        if (participants.contains(user2Id)) {
          // 已存在，直接返回 ID
          return doc.id;
        }
      }
      
      // 2. 獲取用戶資料以存儲基本信息 (優化列表顯示)
      final user1Doc = await _firestore.collection('users').doc(user1Id).get();
      final user2Doc = await _firestore.collection('users').doc(user2Id).get();
      
      if (!user1Doc.exists || !user2Doc.exists) {
        throw Exception('用戶不存在');
      }
      
      final user1 = UserModel.fromMap(user1Doc.data()!, user1Id);
      final user2 = UserModel.fromMap(user2Doc.data()!, user2Id);
      
      // 3. 創建新聊天室
      final docRef = await _chatRoomsCollection.add({
        'participantIds': [user1Id, user2Id],
        'participantData': {
          user1Id: {
            'name': user1.name,
            'avatarUrl': user1.avatarUrl,
          },
          user2Id: {
            'name': user2.name,
            'avatarUrl': user2.avatarUrl,
          },
        },
        'lastMessage': null,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('創建聊天室失敗: $e');
    }
  }

  /// 發送訊息
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String message,
    String type = 'text',
    bool isForwarded = false,
    String? originalSenderId,
    String? originalSenderName,
    String? recipientId, // Optional, but highly recommended for notifications
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // 1. 新增訊息到 messages 集合
      // Note: Using root collection to match existing ChatProvider/ChatDetailScreen logic.
      await _messagesCollection.add({
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarUrl': senderAvatarUrl,
        'message': message, // Standardization on 'message'
        'text': message, // Backward compatibility for ChatProvider
        'type': type,
        'timestamp': timestamp,
        'readBy': [],
        'isForwarded': isForwarded,
        'originalSenderId': originalSenderId,
        'originalSenderName': originalSenderName,
        'isRead': false, // For ChatProvider compatibility
      });

      // 2. 更新聊天室最後訊息
      await _chatRoomsCollection.doc(chatRoomId).update({
        'lastMessage': type == 'text' ? message : '[${type}]',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      });

      // 3. 發送推播通知
      // 如果提供了 recipientId，我們可以直接發送通知
      // 如果沒有提供，我們可以嘗試從 chatRoom 中查找（這會增加延遲，所以最好傳入）
      if (recipientId != null && recipientId.isNotEmpty) {
        try {
          await _functions.httpsCallable('sendNotification').call({
            'recipientUserId': recipientId,
            'senderName': senderName,
            'messageBody': type == 'text' ? message : '傳送了一個附件',
            'chatRoomId': chatRoomId,
          });
        } catch (e) {
          print('發送通知失敗: $e');
          // 通知失敗不應阻擋訊息發送流程
        }
      }
    } catch (e) {
      throw Exception('發送訊息失敗: $e');
    }
  }
}
