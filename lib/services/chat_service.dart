import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/models/user_model.dart';
import 'package:flutter/foundation.dart';

/// 聊天服務 - 處理聊天室的創建與管理
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// 聊天室集合引用
  CollectionReference get _chatRoomsCollection => _firestore.collection('chat_rooms');

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
        'unreadCount': {
          user1Id: 0,
          user2Id: 0,
        }
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
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // 1. 新增訊息到 messages 集合
      await _firestore.collection('messages').add({
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarUrl': senderAvatarUrl,
        'message': message, // Used to be 'text' but now standardizing on 'message'
        'type': type,
        'timestamp': timestamp,
        'readBy': [], // Empty list for readBy
        'isForwarded': isForwarded,
        'originalSenderId': originalSenderId,
        'originalSenderName': originalSenderName,
      });

      // 2. 獲取聊天室資料以確定接收者
      final chatRoomDoc = await _chatRoomsCollection.doc(chatRoomId).get();
      if (!chatRoomDoc.exists) {
        throw Exception('Chat room not found');
      }

      final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
      final participantIds = List<String>.from(chatRoomData['participantIds'] ?? []);

      // 找出接收者 ID (非發送者)
      final recipientId = participantIds.firstWhere(
        (id) => id != senderId,
        orElse: () => '',
      );

      // 3. 更新聊天室最後訊息
      Map<String, dynamic> updateData = {
        'lastMessage': type == 'text' ? message : '[${type}]',
        'lastMessageTime': timestamp,
        'lastMessageSenderId': senderId,
      };

      // 如果有接收者，更新未讀數
      if (recipientId.isNotEmpty) {
        // 使用 FieldValue.increment 更新接收者的未讀數
        // 更新 unreadCount.{recipientId}
        updateData['unreadCount.$recipientId'] = FieldValue.increment(1);
      }

      await _chatRoomsCollection.doc(chatRoomId).update(updateData);

      // 4. 發送推送通知
      if (recipientId.isNotEmpty) {
        try {
          await _sendPushNotification(
            recipientId: recipientId,
            senderId: senderId,
            senderName: senderName,
            message: message,
            type: type,
            chatRoomId: chatRoomId,
          );
        } catch (e) {
          debugPrint('發送推送通知失敗: $e');
          // 不拋出異常，以免影響訊息發送流程
        }
      }

    } catch (e) {
      throw Exception('發送訊息失敗: $e');
    }
  }

  /// 發送推送通知
  Future<void> _sendPushNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String type,
    required String chatRoomId,
  }) async {
    // 獲取接收者資料
    final userDoc = await _firestore.collection('users').doc(recipientId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data() as Map<String, dynamic>;

    // 檢查用戶是否允許通知
    // 預設如果沒有設定則為允許
    // 假設 notificationSettings 結構為 Map<String, bool>
    // 這裡只是一個簡單檢查，Cloud Function 可能會有更完整的邏輯
    final notificationSettings = userData['notificationSettings'] as Map<String, dynamic>?;
    bool pushEnabled = true;
    if (notificationSettings != null && notificationSettings.containsKey('push_enabled')) {
       pushEnabled = notificationSettings['push_enabled'] == true;
    }

    if (!pushEnabled) {
      return;
    }

    // 獲取 FCM Token
    String? fcmToken = userData['fcmToken'];
    List<String> fcmTokens = List<String>.from(userData['fcmTokens'] ?? []);

    if (fcmToken == null && fcmTokens.isEmpty) {
      return;
    }

    // 構建通知內容
    String notificationBody = message;
    if (type == 'image') {
      notificationBody = '傳送了一張圖片';
    } else if (type == 'audio') {
      notificationBody = '傳送了一則語音訊息';
    } else if (type == 'sticker') {
      notificationBody = '傳送了一個貼圖';
    }

    // 截斷過長的訊息
    if (notificationBody.length > 50) {
      notificationBody = '${notificationBody.substring(0, 50)}...';
    }

    // 調用 Cloud Function
    // Cloud Function 名稱假設為 'sendNotification'
    // 根據 memory，應該傳遞 token, title, body, data 等
    final HttpsCallable callable = _functions.httpsCallable('sendNotification');

    await callable.call({
      'token': fcmToken, // 為了兼容舊邏輯，傳遞單個 token
      'tokens': fcmTokens, // 傳遞多個 tokens
      'title': senderName,
      'body': notificationBody,
      'data': {
        'actionType': 'open_chat',
        'actionData': chatRoomId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'senderId': senderId,
      },
      'recipientId': recipientId, // 讓 Cloud Function 處理額外邏輯
    });
  }
}
