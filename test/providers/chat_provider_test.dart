import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0:聊天室權限閘門 + 未讀數單一寫入來源
///
/// ChatProvider 直接 new FirebaseFirestore.instance,無法注入 fake,
/// 這裡以相同的查詢/寫入規則對 fake firestore 驗證核心不變量。
void main() {
  late FakeFirebaseFirestore firestore;

  const me = 'user-me';
  const other = 'user-other';
  const stranger = 'user-stranger';

  setUp(() async {
    firestore = FakeFirebaseFirestore();

    // 我參與的一對一房
    await firestore.collection('chat_rooms').doc('room-mine').set({
      'type': 'direct',
      'participantIds': [me, other],
      'lastMessage': 'hi',
      'lastMessageAt': Timestamp.fromDate(DateTime(2026, 7, 1)),
      'unreadCount': {me: 2, other: 0},
    });
    // 別人的房(權限閘門:不該出現在我的列表)
    await firestore.collection('chat_rooms').doc('room-others').set({
      'type': 'direct',
      'participantIds': [other, stranger],
      'lastMessage': 'secret',
      'lastMessageAt': Timestamp.fromDate(DateTime(2026, 7, 2)),
      'unreadCount': {other: 0, stranger: 0},
    });
    // 我參與的群組房(較新)
    await firestore.collection('chat_rooms').doc('room-group').set({
      'type': 'group',
      'participantIds': [me, other, stranger],
      'lastMessage': 'group hi',
      'lastMessageAt': Timestamp.fromDate(DateTime(2026, 7, 3)),
      'unreadCount': {me: 1, other: 0, stranger: 0},
    });
  });

  group('聊天室權限閘門', () {
    test('列表查詢只回傳 participantIds 含自己的房間', () async {
      // 與 ChatProvider.loadChatRooms 相同的查詢
      final snap = await firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: me)
          .get();

      final ids = snap.docs.map((d) => d.id).toSet();
      expect(ids, {'room-mine', 'room-group'});
      expect(ids.contains('room-others'), isFalse,
          reason: '非參與者的房間不可見(rules 層再擋一次)');
    });
  });

  group('未讀數:CF 為單一寫入來源', () {
    test('sendMessage 的 batch 只寫訊息與 lastMessage,不動 unreadCount',
        () async {
      // 與 ChatProvider.sendMessage 相同的寫入
      final roomRef = firestore.collection('chat_rooms').doc('room-mine');
      final batch = firestore.batch();
      batch.set(roomRef.collection('messages').doc(), {
        'senderId': me,
        'text': 'hello',
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
      batch.update(roomRef, {
        'lastMessage': 'hello',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': me,
      });
      await batch.commit();

      final room = await roomRef.get();
      expect(room.data()?['lastMessage'], 'hello');
      // unreadCount 由 Cloud Function onNewChatMessage 遞增,client 不碰
      expect(Map<String, dynamic>.from(room.data()?['unreadCount']),
          {me: 2, other: 0});

      final msgs = await roomRef.collection('messages').get();
      expect(msgs.docs.length, 1);
    });

    test('markRoomRead 將自己的未讀歸零、不動別人的', () async {
      final roomRef = firestore.collection('chat_rooms').doc('room-group');
      // 與 ChatProvider.markRoomRead 相同的寫入
      await roomRef.update({'unreadCount.$me': 0});

      final room = await roomRef.get();
      final unread = Map<String, dynamic>.from(room.data()?['unreadCount']);
      expect(unread[me], 0);
      expect(unread[other], 0);
      expect(unread[stranger], 0);
    });
  });

  group('訊息排序', () {
    test('pending serverTimestamp(null)視為最新,排在最前', () {
      // 與 ChatProvider.getMessages 相同的排序邏輯
      final messages = <Map<String, dynamic>>[
        {'id': 'old', 'timestamp': Timestamp.fromDate(DateTime(2026, 7, 1))},
        {'id': 'new', 'timestamp': Timestamp.fromDate(DateTime(2026, 7, 2))},
        {'id': 'pending', 'timestamp': null},
      ];
      messages.sort((a, b) {
        final t1 = a['timestamp'] as Timestamp?;
        final t2 = b['timestamp'] as Timestamp?;
        if (t1 == null && t2 == null) return 0;
        if (t1 == null) return -1;
        if (t2 == null) return 1;
        return t2.compareTo(t1);
      });

      expect(messages.map((m) => m['id']).toList(), ['pending', 'new', 'old']);
    });
  });
}
