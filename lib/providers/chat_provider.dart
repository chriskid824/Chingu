import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/badge_count_service.dart';
import 'package:chingu/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();

  List<Map<String, dynamic>> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _totalUnreadCount = 0;
  StreamSubscription<QuerySnapshot>? _unreadSubscription;

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  @override
  void dispose() {
    _unreadSubscription?.cancel();
    super.dispose();
  }

  /// 監聽用戶的未讀訊息數量
  void listenToUnreadCount(String userId) {
    _unreadSubscription?.cancel();

    _unreadSubscription = _firestore
        .collection('chat_rooms')
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .listen((snapshot) {
      int total = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final unreadCountMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        final unreadCount = (unreadCountMap[userId] ?? 0) as int;
        total += unreadCount;
      }

      _totalUnreadCount = total;
      BadgeCountService().updateCount(total);
      notifyListeners();
    }, onError: (e) {
      print('監聽未讀訊息失敗: $e');
    });
  }

  /// 標記聊天室為已讀
  Future<void> markAsRead(String chatRoomId, String userId) async {
    await _chatService.markChatAsRead(chatRoomId, userId);
  }

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
