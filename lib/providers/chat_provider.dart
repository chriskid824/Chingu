import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 載入用戶的聊天室列表
  Future<void> loadChatRooms(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      print('=== ChatProvider.loadChatRooms ===');
      print('用戶 ID: $userId');

      // 查詢包含該用戶的聊天室（暫時移除 orderBy 避免需要索引）
      final chatRoomsQuery = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userId)
          .get();

      print('找到 ${chatRoomsQuery.docs.length} 個聊天室');

      _chatRooms = [];

      for (var doc in chatRoomsQuery.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        
        // 找到對方的 ID
        final otherUserId = participantIds.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // 獲取對方的用戶資料
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
        
        if (!otherUserDoc.exists) continue;

        final otherUser = UserModel.fromMap(
          otherUserDoc.data() as Map<String, dynamic>,
          otherUserDoc.id,
        );

        _chatRooms.add({
          'chatRoomId': doc.id,
          'otherUser': otherUser,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageAt': data['lastMessageAt'],
        });
      }

      print('成功載入 ${_chatRooms.length} 個聊天室');

      _setLoading(false);
    } catch (e) {
      print('載入聊天室錯誤: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 獲取聊天室訊息流
  Stream<List<Map<String, dynamic>>> getMessages(String chatRoomId) {
    return _firestore
        .collection('messages')
        .where('chatRoomId', isEqualTo: chatRoomId)
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // 在內存中排序
      messages.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp?;
        final t2 = b['timestamp'] as Timestamp?;
        if (t1 == null || t2 == null) return 0;
        return t2.compareTo(t1); // 降序
      });

      return messages;
    });
  }

  /// 發送訊息
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // 1. 新增訊息
      await _firestore.collection('messages').add({
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'text': text,
        'timestamp': timestamp,
        'isRead': false,
      });

      // 2. 更新聊天室最後訊息
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': text,
        'lastMessageAt': timestamp,
      });
    } catch (e) {
      print('發送訊息失敗: $e');
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// 設定正在輸入狀態
  Future<void> setTypingStatus({
    required String chatRoomId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      // 使用點符號語法更新 Map 中的特定欄位，避免覆蓋其他用戶的狀態
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'typingIndicators.$userId': isTyping,
      });
    } catch (e) {
      print('更新輸入狀態失敗: $e');
      // 如果文檔不存在或 update 失敗（例如缺少 typingIndicators 欄位），嘗試使用 set merge
      // 注意：這在首次創建 typingIndicators 時可能會發生
      try {
        await _firestore.collection('chat_rooms').doc(chatRoomId).set({
          'typingIndicators': {
            userId: isTyping,
          }
        }, SetOptions(merge: true));
      } catch (e2) {
         print('重試更新輸入狀態失敗: $e2');
      }
    }
  }

  /// 監聽對方輸入狀態
  Stream<bool> getTypingStatusStream(String chatRoomId, String otherUserId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return false;
      final data = snapshot.data();
      if (data == null || !data.containsKey('typingIndicators')) return false;

      final indicators = data['typingIndicators'] as Map<String, dynamic>;
      return indicators[otherUserId] == true;
    });
  }
}
