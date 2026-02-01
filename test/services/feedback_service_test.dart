import 'dart:io';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chingu/services/feedback_service.dart';
import 'package:chingu/models/feedback_model.dart';

@GenerateNiceMocks([
  MockSpec<FirebaseStorage>(),
  MockSpec<Reference>(),
  MockSpec<UploadTask>(),
  MockSpec<TaskSnapshot>(),
])
import 'feedback_service_test.mocks.dart';

void main() {
  group('FeedbackService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late FeedbackService feedbackService;
    late MockReference mockRef;
    late MockReference mockChildRef;
    late MockUploadTask mockUploadTask;
    late MockTaskSnapshot mockTaskSnapshot;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      mockRef = MockReference();
      mockChildRef = MockReference();
      mockUploadTask = MockUploadTask();
      mockTaskSnapshot = MockTaskSnapshot();

      // Setup storage mocks
      when(mockStorage.ref()).thenReturn(mockRef);
      when(mockRef.child(any)).thenReturn(mockChildRef);
      when(mockChildRef.putFile(any)).thenAnswer((_) => mockUploadTask);
      when(mockUploadTask.then(any, onError: anyNamed('onError'))).thenAnswer((invocation) async {
        final onValue = invocation.positionalArguments[0] as FutureOr<dynamic> Function(TaskSnapshot);
        return onValue(mockTaskSnapshot);
      });
      when(mockTaskSnapshot.ref).thenReturn(mockChildRef);
      when(mockChildRef.getDownloadURL()).thenAnswer((_) async => 'https://example.com/image.jpg');

      feedbackService = FeedbackService(
        firestore: fakeFirestore,
        storage: mockStorage,
      );
    });

    test('submitFeedback saves feedback to Firestore correctly', () async {
      final feedback = FeedbackModel(
        id: 'test_id',
        userId: 'user_123',
        type: FeedbackType.suggestion,
        description: 'Great app!',
        contactEmail: 'test@example.com',
        createdAt: DateTime.now(),
      );

      await feedbackService.submitFeedback(feedback, null);

      final snapshot = await fakeFirestore.collection('feedback').doc('test_id').get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['description'], 'Great app!');
      expect(snapshot.data()!['imageUrls'], []);
    });

    test('submitFeedback uploads images and saves feedback', () async {
      final feedback = FeedbackModel(
        id: 'test_id_with_image',
        userId: 'user_123',
        type: FeedbackType.bug,
        description: 'Bug report',
        contactEmail: 'bug@example.com',
        createdAt: DateTime.now(),
      );

      final file = File('test_image.jpg');

      await feedbackService.submitFeedback(feedback, [file]);

      // Verify storage interaction
      verify(mockStorage.ref()).called(1);
      verify(mockRef.child(argThat(contains('feedback_images/test_id_with_image')))).called(1);
      verify(mockChildRef.putFile(file)).called(1);

      // Verify Firestore
      final snapshot = await fakeFirestore.collection('feedback').doc('test_id_with_image').get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['imageUrls'], ['https://example.com/image.jpg']);
    });
  });
}
