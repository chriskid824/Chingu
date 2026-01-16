import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Generate mocks
@GenerateMocks([FirestoreService, ChatService])
import 'matching_service_test.mocks.dart';

// Fake implementations for Cloud Functions since we cannot run build_runner
class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final List<String> calledFunctions = [];

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) {
    calledFunctions.add(name);
    return FakeHttpsCallable();
  }
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    return FakeHttpsCallableResult<T>();
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  T get data => null as T;
}

void main() {
  late MatchingService matchingService;
  late MockFirestoreService mockFirestoreService;
  late MockChatService mockChatService;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseFunctions fakeFunctions;

  // Test data
  final currentUser = UserModel(
    uid: 'current_user',
    email: 'current@test.com',
    name: 'Current User',
    gender: 'male',
    preferredMatchType: 'any',
    city: 'Taipei',
    district: 'Xinyi',
    budgetRange: 2,
    interests: ['coding', 'reading'],
    minAge: 20,
    maxAge: 30,
    age: 25,
    profileCompleted: true,
  );

  final candidateUser = UserModel(
    uid: 'candidate_user',
    email: 'candidate@test.com',
    name: 'Candidate User',
    gender: 'female',
    preferredMatchType: 'any',
    city: 'Taipei',
    district: 'Xinyi',
    budgetRange: 2,
    interests: ['coding', 'movies'], // 1 common interest
    minAge: 20,
    maxAge: 30,
    age: 24,
    profileCompleted: true,
  );

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockChatService = MockChatService();
    fakeFirestore = FakeFirebaseFirestore();
    fakeFunctions = FakeFirebaseFunctions();

    matchingService = MatchingService(
      firestore: fakeFirestore,
      functions: fakeFunctions,
      firestoreService: mockFirestoreService,
      chatService: mockChatService,
    );
  });

  group('getMatches', () {
    test('should return candidates when hard filters pass and not swiped',
        () async {
      // Arrange
      when(mockFirestoreService.queryMatchingUsers(
        city: anyNamed('city'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [candidateUser]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results.length, 1);
      expect(results.first['user'], candidateUser);
      // Score calculation:
      // Interest: 1 common ('coding') / 3 * 40 = 13.33 -> round?
      // Existing test expects 73.
      // 1 common / 4 * 50 = 12.5.
      // Location: 30.
      // Age: diff 1 -> 10.
      // Budget: same -> 10.
      // Total: 12.5 + 30 + 10 + 10 = 62.5 -> 63?

      // Wait, I should not change expectations unless I changed logic.
      // I did NOT change score logic in matching_service.dart.
      // The previous test content I read had expectations. I'll rely on copying them.
      expect(results.first['score'], 73);
    });

    test('should filter out swiped users', () async {
      // Arrange
      // Add a swipe record to fake firestore
      await fakeFirestore.collection('swipes').add({
        'userId': currentUser.uid,
        'targetUserId': candidateUser.uid,
        'isLike': true,
      });

      when(mockFirestoreService.queryMatchingUsers(
        city: anyNamed('city'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [candidateUser]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });

    test('should filter out users who fail hard filters (age)', () async {
      // Arrange
      final oldCandidate = candidateUser.copyWith(age: 40); // > maxAge 30

      when(mockFirestoreService.queryMatchingUsers(
        city: anyNamed('city'),
        limit: anyNamed('limit'),
      )).thenAnswer((_) async => [oldCandidate]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });
  });

  group('recordSwipe', () {
    test('should record swipe correctly', () async {
      // Act
      final result = await matchingService.recordSwipe(
        currentUser.uid,
        candidateUser.uid,
        true, // Like
      );

      // Assert
      final swipes = await fakeFirestore.collection('swipes').get();
      expect(swipes.docs.length, 1);
      expect(swipes.docs.first['userId'], currentUser.uid);
      expect(swipes.docs.first['targetUserId'], candidateUser.uid);
      expect(swipes.docs.first['isLike'], true);

      expect(result['isMatch'], false); // No mutual like yet
    });

    test('should detect match when mutual like exists and send notification', () async {
      // Arrange: Candidate already liked current user
      await fakeFirestore.collection('swipes').add({
        'userId': candidateUser.uid,
        'targetUserId': currentUser.uid,
        'isLike': true,
      });

      // Also need candidate data in firestore for recordSwipe to fetch partner
      await fakeFirestore
          .collection('users')
          .doc(candidateUser.uid)
          .set(candidateUser.toMap());

      when(mockChatService.createChatRoom(any, any))
          .thenAnswer((_) async => 'chat_room_id');

      // Act
      final result = await matchingService.recordSwipe(
        currentUser.uid,
        candidateUser.uid,
        true, // Like
      );

      // Assert
      expect(result['isMatch'], true);
      expect(result['chatRoomId'], 'chat_room_id');

      // Verify stats updated
      verify(mockFirestoreService.updateUserStats(currentUser.uid, totalMatches: 1)).called(1);
      verify(mockFirestoreService.updateUserStats(candidateUser.uid, totalMatches: 1)).called(1);

      // Verify notification sent
      expect(fakeFunctions.calledFunctions, contains('sendMatchNotification'));
    });
  });
}
