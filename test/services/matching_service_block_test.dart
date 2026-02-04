import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirestoreService, ChatService])
import 'matching_service_block_test.mocks.dart';

void main() {
  late MatchingService matchingService;
  late MockFirestoreService mockFirestoreService;
  late MockChatService mockChatService;
  late FakeFirebaseFirestore fakeFirestore;

  final currentUser = UserModel(
    uid: 'current_user',
    email: 'current@test.com',
    name: 'Current User',
    gender: 'male',
    preferredMatchType: 'any',
    city: 'Taipei',
    district: 'Xinyi',
    job: 'dev',
    budgetRange: 2,
    interests: ['coding'],
    country: 'Taiwan',
    minAge: 20,
    maxAge: 30,
    age: 25,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );

  final candidateUser = UserModel(
    uid: 'candidate_user',
    name: 'Candidate',
    email: 'candidate@test.com',
    gender: 'female',
    age: 24,
    preferredMatchType: 'any',
    city: 'Taipei',
    district: 'Xinyi',
    job: 'dev',
    budgetRange: 2,
    interests: ['coding'],
    country: 'Taiwan',
    minAge: 20,
    maxAge: 30,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockChatService = MockChatService();
    fakeFirestore = FakeFirebaseFirestore();

    matchingService = MatchingService(
      firestore: fakeFirestore,
      firestoreService: mockFirestoreService,
      chatService: mockChatService,
    );
  });

  group('MatchingService Block Filtering', () {
    test('should filter out users blocked by current user', () async {
      // Arrange
      final blockingUser = currentUser.copyWith(
        blockedUserIds: [candidateUser.uid],
      );

      when(mockFirestoreService.queryMatchingUsers(
        city: anyNamed('city'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [candidateUser]);

      // Act
      final results = await matchingService.getMatches(blockingUser);

      // Assert
      expect(results, isEmpty);
    });

    test('should filter out users who blocked current user', () async {
      // Arrange
      // Since copyWith doesn't support changing uid, we rely on the candidateUser object
      // but we need to inject the blockedUserIds into it.
      // Since blockedUserIds is final, we have to create a new instance or use copyWith if updated.
      // We added copyWith support for blockedUserIds in previous steps.

      final blockerCandidate = candidateUser.copyWith(
        blockedUserIds: [currentUser.uid],
      );

      when(mockFirestoreService.queryMatchingUsers(
        city: anyNamed('city'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [blockerCandidate]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });
  });
}
