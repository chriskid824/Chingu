import 'package:chingu/services/chat_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake implementations
class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final FakeHttpsCallable callable = FakeHttpsCallable();

  @override
  HttpsCallable httpsCallable(String? name, {HttpsCallableOptions? options}) {
    if (name == 'sendNotification') {
      return callable;
    }
    throw UnimplementedError();
  }
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  final List<dynamic> calls = [];

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    calls.add(data);
    return FakeHttpsCallableResult<T>();
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  final T data = {} as T;
}

void main() {
  late ChatService chatService;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseFunctions fakeFunctions;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fakeFunctions = FakeFirebaseFunctions();
    chatService = ChatService(
      firestore: fakeFirestore,
      functions: fakeFunctions,
    );
  });

  group('sendMessage', () {
    test('should send notification when receiver has fcmToken', () async {
      final senderId = 'sender_1';
      final receiverId = 'receiver_1';
      final chatRoomId = 'chat_1';
      final token = 'test_token_123';

      // Setup Chat Room
      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
        'participantIds': [senderId, receiverId],
        'lastMessage': null,
      });

      // Setup Receiver User with Token
      await fakeFirestore.collection('users').doc(receiverId).set({
        'name': 'Receiver',
        'email': 'r@test.com',
        'fcmToken': token,
        // Minimal required fields to avoid errors if logic checks them (it doesn't seem to)
      });

      // Act
      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: 'Sender',
        message: 'Hello',
      );

      // Assert
      // 1. Check message is saved
      final messages = await fakeFirestore.collection('messages').get();
      expect(messages.docs.length, 1);
      expect(messages.docs.first['message'], 'Hello');

      // 2. Check notification function called
      expect(fakeFunctions.callable.calls.length, 1);
      final callData = fakeFunctions.callable.calls.first as Map;
      expect(callData['token'], token);
      expect(callData['title'], 'Sender');
      expect(callData['body'], 'Hello');
      expect(callData['data']['type'], 'chat');
      expect(callData['data']['chatId'], chatRoomId);
    });

    test('should NOT send notification when receiver has NO token', () async {
      final senderId = 'sender_1';
      final receiverId = 'receiver_1';
      final chatRoomId = 'chat_1';

      // Setup Chat Room
      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
        'participantIds': [senderId, receiverId],
      });

      // Setup Receiver User WITHOUT Token
      await fakeFirestore.collection('users').doc(receiverId).set({
        'name': 'Receiver',
      });

      // Act
      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: 'Sender',
        message: 'Hello',
      );

      // Assert
      expect(fakeFunctions.callable.calls.length, 0);
    });
  });
}
