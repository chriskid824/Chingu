import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/badge_count_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  // TODO: 實作真實的未讀訊息計數。目前預設為 0，等待後端支援。
  final int _totalUnreadCount = 0;

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

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
      int totalUnreadCount = 0;

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

        // 獲取未讀數量
        final unreadCountMap = Map<String, int>.from(data['unreadCount'] ?? {});
        final unreadCount = unreadCountMap[userId] ?? 0;
        totalUnreadCount += unreadCount;

        _chatRooms.add({
          'chatRoomId': doc.id,
          'otherUser': otherUser,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageAt': data['lastMessageAt'],
          'unreadCount': unreadCount,
        });
      }

      // 更新 App Badge
      await BadgeCountService().updateCount(totalUnreadCount);

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
    String type = 'text',
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // 1. 新增訊息
      await _firestore.collection('messages').add({
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'text': text,
        'type': type,
        'timestamp': timestamp,
        'isRead': false,
      });

      // 2. 更新聊天室最後訊息
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'lastMessage': text,
        'lastMessageAt': timestamp,
      });

      // 3. 發送推播通知
      try {
        final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
        if (chatRoomDoc.exists) {
          final data = chatRoomDoc.data() as Map<String, dynamic>;
          final participantIds = List<String>.from(data['participantIds'] ?? []);
          final recipientId = participantIds.firstWhere(
            (id) => id != senderId,
            orElse: () => '',
          );

          if (recipientId.isNotEmpty) {
            final userDoc = await _firestore.collection('users').doc(recipientId).get();
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final fcmToken = userData['fcmToken'] as String?;

              if (fcmToken != null) {
                // 獲取發送者名稱
                String senderName = 'New Message';
                try {
                  final senderDoc = await _firestore.collection('users').doc(senderId).get();
                  if (senderDoc.exists) {
                    senderName = senderDoc.data()?['name'] ?? 'New Message';
                  }
                } catch (e) {
                  print('獲取發送者名稱失敗: $e');
                }

                await FirebaseFunctions.instance.httpsCallable('sendChatNotification').call({
                  'token': fcmToken,
                  'title': senderName,
                  'body': type == 'text' ? text : (type == 'image' ? '傳送了一張圖片' : '傳送了一則訊息'),
                  'imageUrl': type == 'image' ? text : null,
                });
              }
            }
          }
        }
      } catch (e) {
        print('發送推播通知失敗: $e');
      }
    } catch (e) {
      print('發送訊息失敗: $e');
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
