import 'package:chingu/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final Map<String, FakeHttpsCallable> callables = {};

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    callables.putIfAbsent(name, () => FakeHttpsCallable());
    return callables[name]!;
  }
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  Map<String, dynamic>? lastCallData;
  int callCount = 0;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    lastCallData = data as Map<String, dynamic>?;
    callCount++;
    return FakeHttpsCallableResult<T>();
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  T get data => throw UnimplementedError();
}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseFunctions fakeFunctions;
  late ChatService chatService;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeFunctions = FakeFirebaseFunctions();
    chatService = ChatService(
      firestore: fakeFirestore,
      functions: fakeFunctions,
    );
  });

  group('ChatService', () {
    test('sendMessage adds message to Firestore and updates chat room', () async {
      const chatRoomId = 'chat123';

      // Create chat room first
      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
        'lastMessage': 'old',
      });

      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: 'user1',
        senderName: 'User One',
        message: 'Hello World',
        recipientId: 'user2',
      );

      // Verify message added
      final messages = await fakeFirestore.collection('messages').get();
      expect(messages.docs.length, 1);
      final msg = messages.docs.first.data();
      expect(msg['message'], 'Hello World');
      expect(msg['text'], 'Hello World');
      expect(msg['senderName'], 'User One');

      // Verify chat room updated
      final chatRoom = await fakeFirestore.collection('chat_rooms').doc(chatRoomId).get();
      expect(chatRoom.data()!['lastMessage'], 'Hello World');
      expect(chatRoom.data()!['lastMessageAt'], isNotNull);
    });

    test('sendMessage sends push notification when recipientId is provided', () async {
      const chatRoomId = 'chat123';
      const senderName = 'User One';
      const message = 'Hello World';
      const recipientId = 'user2';

      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({});

      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: 'user1',
        senderName: senderName,
        message: message,
        recipientId: recipientId,
      );

      final callable = fakeFunctions.callables['sendNotification'];
      expect(callable, isNotNull);
      expect(callable!.callCount, 1);
      expect(callable.lastCallData, {
        'userId': recipientId,
        'title': senderName,
        'body': message,
        'type': 'chat_message',
      });
    });

    test('sendMessage truncates long message for notification', () async {
      const chatRoomId = 'chat123';
      const senderName = 'User One';
      const longMessage = 'This is a very long message that is definitely longer than twenty characters';
      const recipientId = 'user2';

      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({});

      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: 'user1',
        senderName: senderName,
        message: longMessage,
        recipientId: recipientId,
      );

      final callable = fakeFunctions.callables['sendNotification'];
      expect(callable, isNotNull);
      final expectedBody = '${longMessage.substring(0, 20)}...';
      expect(callable!.lastCallData!['body'], expectedBody);
    });
  });
}
