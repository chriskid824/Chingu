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

      // 依最後訊息時間排序(新的在前);lastMessageAt 缺漏時退回 lastMessageTime
      int compareRooms(Map<String, dynamic> a, Map<String, dynamic> b) {
        final t1 = (a['lastMessageAt'] ?? a['lastMessageTime']) as Timestamp?;
        final t2 = (b['lastMessageAt'] ?? b['lastMessageTime']) as Timestamp?;
        if (t1 == null && t2 == null) return 0;
        if (t1 == null) return 1;
        if (t2 == null) return -1;
        return t2.compareTo(t1);
      }

      _chatRooms.sort(compareRooms);
      _groupChatRooms.sort(compareRooms);

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
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Dart 端排序（避免需要 Firestore composite index）
      // timestamp 為 null = 本地樂觀寫入的 serverTimestamp 尚未回填,
      // 視為「最新」排最前,否則剛送出的訊息會閃現在最舊的位置
      messages.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp?;
        final t2 = b['timestamp'] as Timestamp?;
        if (t1 == null && t2 == null) return 0;
        if (t1 == null) return -1;
        if (t2 == null) return 1;
        return t2.compareTo(t1); // 降序：最新的在前
      });

      return messages;
    });
  }

  /// 進入聊天室時清除自己的未讀數
  Future<void> markRoomRead(String chatRoomId, String userId) async {
    try {
      await _firestore.collection('chat_rooms').doc(chatRoomId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('清除未讀失敗: $e');
      }
    }
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
      final roomRef = _firestore.collection('chat_rooms').doc(chatRoomId);

      // 訊息 + 最後訊息用 batch 原子寫入,避免斷網時列表與內容不一致。
      // 其他參與者的 unreadCount 由 Cloud Function onNewChatMessage 遞增
      // (單一寫入來源,client 不再遞增以免每則 +2)
      final batch = _firestore.batch();
      batch.set(roomRef.collection('messages').doc(), {
        'senderId': senderId,
        'text': text,
        'type': type,
        'timestamp': timestamp,
        'isRead': false,
      });
      batch.update(roomRef, {
        'lastMessage': text,
        'lastMessageAt': timestamp,
        'lastMessageSenderId': senderId,
      });
      await batch.commit();
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
