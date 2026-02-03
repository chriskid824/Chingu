import 'package:chingu/services/chat_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks
@GenerateMocks([FirebaseFunctions, HttpsCallable])
import 'chat_service_test.mocks.dart';

void main() {
  late ChatService chatService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();

    chatService = ChatService(
      firestore: fakeFirestore,
      functions: mockFunctions,
    );
  });

  group('sendMessage', () {
    test('should send message and trigger notification with provided recipientId', () async {
      // Arrange
      const chatRoomId = 'chat_room_id';
      const senderId = 'sender_id';
      const senderName = 'Sender Name';
      const message = 'Hello, this is a test message that is longer than 20 chars';
      const recipientId = 'recipient_id';

      // Mock Cloud Function
      when(mockFunctions.httpsCallable('sendNotification'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => MockHttpsCallableResult());

      // Setup chat room
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
      // 1. Check message in Firestore
      final messages = await fakeFirestore.collection('messages').get();
      expect(messages.docs.length, 1);
      expect(messages.docs.first['message'], message);

      // 2. Check notification call
      verify(mockFunctions.httpsCallable('sendNotification')).called(1);

      final expectedPreview = 'Hello, this is a tes...'; // 20 chars + ...

      verify(mockCallable.call(argThat(predicate((Map<String, dynamic> data) {
        return data['recipientId'] == recipientId &&
               data['title'] == senderName &&
               data['body'] == expectedPreview &&
               data['data']['type'] == 'new_message' &&
               data['data']['chatRoomId'] == chatRoomId;
      })))).called(1);
    });

    test('should fallback to chat room participants if recipientId is missing', () async {
      // Arrange
      const chatRoomId = 'chat_room_id_fallback';
      const senderId = 'sender_id';
      const recipientId = 'recipient_id_fallback';

      await fakeFirestore.collection('chat_rooms').doc(chatRoomId).set({
        'participantIds': [senderId, recipientId],
      });

      when(mockFunctions.httpsCallable('sendNotification'))
          .thenReturn(mockCallable);
      when(mockCallable.call(any)).thenAnswer((_) async => MockHttpsCallableResult());

      // Act
      await chatService.sendMessage(
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderName: 'Sender',
        message: 'Hi',
      );

      // Assert
      verify(mockFunctions.httpsCallable('sendNotification')).called(1);

      verify(mockCallable.call(argThat(predicate((Map<String, dynamic> data) {
        return data['recipientId'] == recipientId;
      })))).called(1);
    });
  });
}

// Simple mock for HttpsCallableResult
class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}
