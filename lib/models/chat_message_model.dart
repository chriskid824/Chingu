import 'package:cloud_firestore/cloud_firestore.dart';

/// 聊天訊息模型
class ChatMessageModel {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String message;
  final String type; // 'text', 'image', 'system'
  final DateTime timestamp;
  final List<String> readBy; // 已讀用戶 UID 列表
  final bool isEdited;
  final DateTime? editedAt;

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.message,
    this.type = 'text',
    required this.timestamp,
    this.readBy = const [],
    this.isEdited = false,
    this.editedAt,
  });

  /// 從 Firestore 文檔創建 ChatMessageModel
  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 ChatMessageModel
  factory ChatMessageModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessageModel(
      id: id,
      chatRoomId: map['chatRoomId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderAvatarUrl: map['senderAvatarUrl'],
      message: map['message'] ?? map['text'] ?? '',
      type: map['type'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      readBy: List<String>.from(map['readBy'] ?? []),
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null
          ? (map['editedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatarUrl': senderAvatarUrl,
      'message': message,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'readBy': readBy,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
    };
  }

  /// 檢查用戶是否已讀
  bool isReadBy(String userId) {
    return readBy.contains(userId);
  }

  /// 複製並更新已讀列表
  ChatMessageModel copyWith({
    List<String>? readBy,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return ChatMessageModel(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarUrl: senderAvatarUrl,
      message: message,
      type: type,
      timestamp: timestamp,
      readBy: readBy ?? this.readBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}

/// 聊天室模型
class ChatRoomModel {
  final String id;
  final String dinnerEventId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantAvatars;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount; // uid -> unread count
  final DateTime createdAt;

  ChatRoomModel({
    required this.id,
    required this.dinnerEventId,
    required this.participantIds,
    required this.participantNames,
    required this.participantAvatars,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.unreadCount = const {},
    required this.createdAt,
  });

  /// 從 Firestore 文檔創建 ChatRoomModel
  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatRoomModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 ChatRoomModel
  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      id: id,
      dinnerEventId: map['dinnerEventId'] ?? '',
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantAvatars: Map<String, String?>.from(map['participantAvatars'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageTime: map['lastMessageTime'] != null
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : null,
      lastMessageSenderId: map['lastMessageSenderId'],
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'dinnerEventId': dinnerEventId,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantAvatars': participantAvatars,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// 獲取用戶的未讀數量
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// 複製並更新部分欄位
  ChatRoomModel copyWith({
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
  }) {
    return ChatRoomModel(
      id: id,
      dinnerEventId: dinnerEventId,
      participantIds: participantIds,
      participantNames: participantNames,
      participantAvatars: participantAvatars,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
    );
  }
}























