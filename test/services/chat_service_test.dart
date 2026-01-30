import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:chingu/services/chat_service.dart';

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final Map<String, FakeHttpsCallable> callables = {};

  @override
  HttpsCallable httpsCallable(String? name, {HttpsCallableOptions? options}) {
    final key = name ?? 'default';
    callables.putIfAbsent(key, () => FakeHttpsCallable());
    return callables[key]!;
  }
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  List<dynamic> calledWith = [];

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    calledWith.add(data);
    return FakeHttpsCallableResult<T>();
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  T get data => null as T;
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

  test('sendMessage should trigger notification when recipientId is provided', () async {
    // Arrange
    const chatRoomId = 'chat123';
    const senderId = 'user1';
    const senderName = 'Alice';
    const recipientId = 'user2';
    const message = 'Hello world this is a long message';

    // Create chat room first (required for update)
    await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
      'participantIds': [senderId, recipientId],
    });

    // Act
    await chatService.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      recipientId: recipientId,
    );

    // Assert
    // 1. Verify Firestore message created
    final messages = await fakeFirestore.collection('messages').get();
    expect(messages.docs.length, 1);
    final msgData = messages.docs.first.data();
    expect(msgData['text'], message); // Compatibility field
    expect(msgData['message'], message); // New field

    // 2. Verify Cloud Function called
    final callable = fakeFunctions.callables['sendNotification'];
    expect(callable, isNotNull);
    expect(callable!.calledWith.length, 1);

    final data = callable.calledWith.first as Map<String, dynamic>;
    expect(data['recipientId'], recipientId);
    expect(data['title'], senderName);
    expect(data['body'], 'Hello world this is ...'); // Truncated
    expect(data['data']['actionType'], 'open_chat');
    expect(data['data']['actionData'], chatRoomId);
  });

  test('sendMessage should NOT trigger notification when recipientId is null', () async {
    // Arrange
    const chatRoomId = 'chat123';
    const senderId = 'user1';
    const senderName = 'Alice';
    const message = 'Hello';

    // Create chat room first (required for update)
    await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
      'participantIds': [senderId],
    });

    // Act
    await chatService.sendMessage(
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      recipientId: null,
    );

    // Assert
    // Cloud Function should NOT be called
    expect(fakeFunctions.callables['sendNotification'], isNull);
  });
}
