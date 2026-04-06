import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/badge_count_service.dart';

class ChatProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _chatRooms = [];       // 1 對 1
  List<Map<String, dynamic>> _groupChatRooms = [];  // 群組聊天
  bool _isLoading = false;
  String? _errorMessage;
  int _totalUnreadCount = 0;

  List<Map<String, dynamic>> get chatRooms => _chatRooms;
  List<Map<String, dynamic>> get groupChatRooms => _groupChatRooms;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get totalUnreadCount => _totalUnreadCount;

  /// 載入用戶的聊天室列表
  Future<void> loadChatRooms(String userId) async {
    try {
      _setLoading(true);
      _errorMessage = null;

      if (kDebugMode) {
        debugPrint('=== ChatProvider.loadChatRooms ===');
        debugPrint('用戶 ID: $userId');
      }

      // 查詢包含該用戶的聊天室（暫時移除 orderBy 避免需要索引）
      final chatRoomsQuery = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userId)
          .get();

      debugPrint('找到 ${chatRoomsQuery.docs.length} 個聊天室');

      // 取得封鎖名單以過濾聊天列表
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final blockedUserIds = Set<String>.from(userData?['blockedUserIds'] ?? []);

      _chatRooms = [];
      _groupChatRooms = [];
      int totalUnreadCount = 0;

      for (var doc in chatRoomsQuery.docs) {
        final data = doc.data();
        final participantIds = List<String>.from(data['participantIds'] ?? []);
        final type = data['type'] as String? ?? 'direct';

        // 獲取未讀數量
        final unreadCountMap = Map<String, int>.from(
          (data['unreadCount'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ?? {},
        );
        final unreadCount = unreadCountMap[userId] ?? 0;
        totalUnreadCount += unreadCount;

        // ─── 群組聊天 ───
        if (type == 'group') {
          _groupChatRooms.add({
            'chatRoomId': doc.id,
            'groupId': data['groupId'] ?? '',
            'name': data['name'] ?? '晚餐群組',
            'participantIds': participantIds,
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageAt': data['lastMessageAt'],
            'unreadCount': unreadCount,
          });
          continue;
        }

        // ─── 1 對 1 聊天 ───
        final otherUserId = participantIds.firstWhere(
          (id) => id != userId,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) continue;

        // 跳過被封鎖的用戶
        if (blockedUserIds.contains(otherUserId)) continue;

        // 獲取對方的用戶資料
        final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

        if (!otherUserDoc.exists) continue;

        // 檢查對方是否也封鎖了我
        final otherUserData = otherUserDoc.data();
        final otherBlockedIds = List<String>.from(otherUserData?['blockedUserIds'] ?? []);
        if (otherBlockedIds.contains(userId)) continue;

        final otherUser = UserModel.fromMap(
          otherUserDoc.data() as Map<String, dynamic>,
          otherUserDoc.id,
        );

        _chatRooms.add({
          'chatRoomId': doc.id,
          'otherUser': otherUser,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageAt': data['lastMessageAt'],
          'unreadCount': unreadCount,
        });
      }

      // 更新 App Badge
      _totalUnreadCount = totalUnreadCount;
      await BadgeCountService().updateCount(totalUnreadCount);

      if (kDebugMode) {
        debugPrint('成功載入 ${_chatRooms.length} 個聊天室');
      }

      _setLoading(false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('載入聊天室錯誤: $e');
      }
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 獲取聊天室訊息流（子集合 chat_rooms/{id}/messages）
  Stream<List<Map<String, dynamic>>> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// 發送訊息（寫入子集合 chat_rooms/{id}/messages）
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String text,
    String type = 'text',
  }) async {
    try {
      final timestamp = FieldValue.serverTimestamp();

      // 1. 新增訊息到子集合
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
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

      // 3. 遞增其他參與者的 unreadCount
      final chatRoomDoc = await _firestore.collection('chat_rooms').doc(chatRoomId).get();
      if (chatRoomDoc.exists) {
        final participantIds = List<String>.from(chatRoomDoc.data()?['participantIds'] ?? []);
        final updates = <String, dynamic>{};
        for (final id in participantIds) {
          if (id != senderId) {
            updates['unreadCount.$id'] = FieldValue.increment(1);
          }
        }
        if (updates.isNotEmpty) {
          await _firestore.collection('chat_rooms').doc(chatRoomId).update(updates);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('發送訊息失敗: $e');
      }
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
