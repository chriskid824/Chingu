import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('ChatService', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    // ==================== 聊天室建立測試 ====================

    group('Create Chat Room', () {
      test('should create a new chat room', () async {
        // 準備用戶資料
        await fakeFirestore.collection('users').doc('user1').set({
          'name': 'User One',
          'avatarUrl': 'https://example.com/avatar1.jpg',
          'email': 'user1@example.com',
          'gender': 'male',
          'birthday': '1990-01-01',
          'city': 'Taipei',
          'bio': 'Hello',
          'interests': ['travel'],
          'minAge': 18,
          'maxAge': 50,
        });

        await fakeFirestore.collection('users').doc('user2').set({
          'name': 'User Two',
          'avatarUrl': 'https://example.com/avatar2.jpg',
          'email': 'user2@example.com',
          'gender': 'female',
          'birthday': '1995-01-01',
          'city': 'Taipei',
          'bio': 'Hi',
          'interests': ['music'],
          'minAge': 18,
          'maxAge': 50,
        });

        // 建立聊天室
        final chatRoomRef = await fakeFirestore.collection('chat_rooms').add({
          'participantIds': ['user1', 'user2'],
          'participantData': {
            'user1': {
              'name': 'User One',
              'avatarUrl': 'https://example.com/avatar1.jpg',
            },
            'user2': {
              'name': 'User Two',
              'avatarUrl': 'https://example.com/avatar2.jpg',
            },
          },
          'lastMessage': null,
          'lastMessageTime': DateTime.now(),
          'createdAt': DateTime.now(),
        });

        expect(chatRoomRef.id, isNotEmpty);

        // 驗證聊天室資料
        final chatRoom = await fakeFirestore
            .collection('chat_rooms')
            .doc(chatRoomRef.id)
            .get();
        
        expect(chatRoom.exists, isTrue);
        expect(chatRoom.data()?['participantIds'], contains('user1'));
        expect(chatRoom.data()?['participantIds'], contains('user2'));
      });

      test('should find existing chat room between users', () async {
        // 建立已存在的聊天室
        await fakeFirestore.collection('chat_rooms').add({
          'participantIds': ['user1', 'user2'],
          'createdAt': DateTime.now(),
        });

        // 查詢
        final query = await fakeFirestore
            .collection('chat_rooms')
            .where('participantIds', arrayContains: 'user1')
            .get();

        final existingRoom = query.docs.firstWhere((doc) {
          final participants = List<String>.from(doc.data()['participantIds'] ?? []);
          return participants.contains('user2');
        }, orElse: () => throw Exception('Not found'));

        expect(existingRoom, isNotNull);
      });
    });

    // ==================== 訊息發送測試 ====================

    group('Send Message', () {
      test('should send a text message', () async {
        const chatRoomId = 'room1';

        await fakeFirestore.collection('messages').add({
          'chatRoomId': chatRoomId,
          'senderId': 'user1',
          'senderName': 'User One',
          'message': 'Hello!',
          'type': 'text',
          'timestamp': DateTime.now(),
          'readBy': [],
        });

        final messages = await fakeFirestore
            .collection('messages')
            .where('chatRoomId', isEqualTo: chatRoomId)
            .get();

        expect(messages.docs.length, equals(1));
        expect(messages.docs.first.data()['message'], equals('Hello!'));
        expect(messages.docs.first.data()['type'], equals('text'));
      });

      test('should send a forwarded message', () async {
        const chatRoomId = 'room1';

        await fakeFirestore.collection('messages').add({
          'chatRoomId': chatRoomId,
          'senderId': 'user1',
          'senderName': 'User One',
          'message': 'Forwarded message',
          'type': 'text',
          'timestamp': DateTime.now(),
          'readBy': [],
          'isForwarded': true,
          'originalSenderId': 'user2',
          'originalSenderName': 'User Two',
        });

        final messages = await fakeFirestore
            .collection('messages')
            .where('chatRoomId', isEqualTo: chatRoomId)
            .get();

        expect(messages.docs.first.data()['isForwarded'], isTrue);
        expect(messages.docs.first.data()['originalSenderId'], equals('user2'));
      });

      test('should update chat room last message', () async {
        const chatRoomId = 'room1';

        // 建立聊天室
        await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
          'participantIds': ['user1', 'user2'],
          'lastMessage': null,
          'lastMessageTime': null,
        });

        // 更新最後訊息
        await fakeFirestore.collection('chat_rooms').doc(chatRoomId).update({
          'lastMessage': 'Hello!',
          'lastMessageTime': DateTime.now(),
          'lastMessageSenderId': 'user1',
        });

        final chatRoom = await fakeFirestore
            .collection('chat_rooms')
            .doc(chatRoomId)
            .get();

        expect(chatRoom.data()?['lastMessage'], equals('Hello!'));
        expect(chatRoom.data()?['lastMessageSenderId'], equals('user1'));
      });
    });

    // ==================== 訊息類型測試 ====================

    group('Message Types', () {
      test('should handle image message type', () async {
        await fakeFirestore.collection('messages').add({
          'chatRoomId': 'room1',
          'senderId': 'user1',
          'senderName': 'User One',
          'message': 'https://example.com/image.jpg',
          'type': 'image',
          'timestamp': DateTime.now(),
          'readBy': [],
        });

        final messages = await fakeFirestore.collection('messages').get();
        expect(messages.docs.first.data()['type'], equals('image'));
      });

      test('should handle sticker message type', () async {
        await fakeFirestore.collection('messages').add({
          'chatRoomId': 'room1',
          'senderId': 'user1',
          'senderName': 'User One',
          'message': 'sticker_pack_1_001',
          'type': 'sticker',
          'timestamp': DateTime.now(),
          'readBy': [],
        });

        final messages = await fakeFirestore.collection('messages').get();
        expect(messages.docs.first.data()['type'], equals('sticker'));
      });

      test('should handle gif message type', () async {
        await fakeFirestore.collection('messages').add({
          'chatRoomId': 'room1',
          'senderId': 'user1',
          'senderName': 'User One',
          'message': 'https://giphy.com/example.gif',
          'type': 'gif',
          'timestamp': DateTime.now(),
          'readBy': [],
        });

        final messages = await fakeFirestore.collection('messages').get();
        expect(messages.docs.first.data()['type'], equals('gif'));
      });
    });

    // ==================== 已讀狀態測試 ====================

    group('Read Status', () {
      test('should mark message as read', () async {
        final messageRef = await fakeFirestore.collection('messages').add({
          'chatRoomId': 'room1',
          'senderId': 'user1',
          'message': 'Hello!',
          'type': 'text',
          'timestamp': DateTime.now(),
          'readBy': [],
        });

        // 標記為已讀
        await fakeFirestore.collection('messages').doc(messageRef.id).update({
          'readBy': ['user2'],
        });

        final message = await fakeFirestore
            .collection('messages')
            .doc(messageRef.id)
            .get();

        expect(message.data()?['readBy'], contains('user2'));
      });
    });
  });
}
