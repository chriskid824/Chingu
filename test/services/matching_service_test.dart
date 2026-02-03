import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Manual Mocks with robust noSuchMethod implementation
class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<List<UserModel>> queryMatchingUsers({
    required String city,
    int? budgetRange,
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) {
    return super.noSuchMethod(
      Invocation.method(#queryMatchingUsers, [], {
        #city: city,
        #budgetRange: budgetRange,
        #gender: gender,
        #minAge: minAge,
        #maxAge: maxAge,
        #limit: limit,
      }),
      returnValue: Future.value(<UserModel>[]),
      returnValueForMissingStub: Future.value(<UserModel>[]),
    ) as Future<List<UserModel>>;
  }

  @override
  Future<void> updateUserStats(
    String uid, {
    int? totalDinners,
    int? totalMatches,
  }) {
    return super.noSuchMethod(
      Invocation.method(#updateUserStats, [uid], {
        #totalDinners: totalDinners,
        #totalMatches: totalMatches,
      }),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

class MockChatService extends Mock implements ChatService {
  @override
  Future<String> createChatRoom(String user1Id, String user2Id) {
    return super.noSuchMethod(
      Invocation.method(#createChatRoom, [user1Id, user2Id]),
      returnValue: Future.value(''),
      returnValueForMissingStub: Future.value(''),
    ) as Future<String>;
  }
}

class MockNotificationService extends Mock implements NotificationService {
  @override
  Future<void> sendMatchNotification({
    required String currentUserId,
    required String targetUserId,
    required String chatRoomId,
  }) {
    return super.noSuchMethod(
      Invocation.method(#sendMatchNotification, [], {
        #currentUserId: currentUserId,
        #targetUserId: targetUserId,
        #chatRoomId: chatRoomId,
      }),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }
}

void main() {
  late MatchingService matchingService;
  late MockFirestoreService mockFirestoreService;
  late MockChatService mockChatService;
  late MockNotificationService mockNotificationService;
  late FakeFirebaseFirestore fakeFirestore;

  // Test data
  final now = DateTime.now();
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
    country: 'Taiwan',
    job: 'Developer',
    createdAt: now,
    lastLogin: now,
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
    country: 'Taiwan',
    job: 'Designer',
    createdAt: now,
    lastLogin: now,
  );

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    mockChatService = MockChatService();
    mockNotificationService = MockNotificationService();
    fakeFirestore = FakeFirebaseFirestore();

    matchingService = MatchingService(
      firestore: fakeFirestore,
      firestoreService: mockFirestoreService,
      chatService: mockChatService,
      notificationService: mockNotificationService,
    );
  });

  group('getMatches', () {
    test('should return candidates when hard filters pass and not swiped',
        () async {
      // Arrange
      // Using anyNamed inside specific argument if mockito supports it, or explicit
      // Since manual mocks can be tricky with argument matchers, explicit is safer for now.
      when(mockFirestoreService.queryMatchingUsers(
        city: 'Taipei',
        limit: 50,
      )).thenAnswer((_) async => [candidateUser]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results.length, 1);
      expect(results.first['user'].uid, candidateUser.uid);
      expect(results.first['score'], 63);
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
        city: 'Taipei',
        limit: 50,
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
        city: 'Taipei',
        limit: 50,
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

    test('should detect match when mutual like exists', () async {
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

      when(mockChatService.createChatRoom(currentUser.uid, candidateUser.uid))
          .thenAnswer((_) async => 'chat_room_id');

      // Stub updateUserStats
      when(mockFirestoreService.updateUserStats(currentUser.uid, totalMatches: 1))
          .thenAnswer((_) async {});
      when(mockFirestoreService.updateUserStats(candidateUser.uid, totalMatches: 1))
          .thenAnswer((_) async {});

      // Stub sendMatchNotification
      when(mockNotificationService.sendMatchNotification(
        currentUserId: currentUser.uid,
        targetUserId: candidateUser.uid,
        chatRoomId: 'chat_room_id',
      )).thenAnswer((_) async => {});

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
      verify(mockNotificationService.sendMatchNotification(
        currentUserId: currentUser.uid,
        targetUserId: candidateUser.uid,
        chatRoomId: 'chat_room_id',
      )).called(1);
    });
  });
}
