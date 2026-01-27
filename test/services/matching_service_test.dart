import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MatchingService matchingService;
  late FakeFirestoreService fakeFirestoreService;
  late FakeChatService fakeChatService;
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
    job: 'Developer',
    country: 'Taiwan',
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
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
    job: 'Designer',
    country: 'Taiwan',
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );

  setUp(() {
    fakeFirestoreService = FakeFirestoreService();
    fakeChatService = FakeChatService();
    fakeFirestore = FakeFirebaseFirestore();
    fakeFunctions = FakeFirebaseFunctions();

    matchingService = MatchingService(
      firestore: fakeFirestore,
      firestoreService: fakeFirestoreService,
      chatService: fakeChatService,
      functions: fakeFunctions,
    );
  });

  group('getMatches', () {
    test('should return candidates when hard filters pass and not swiped',
        () async {
      // Arrange
      fakeFirestoreService.queryMatchingUsersStub = ({required city, limit, budgetRange}) async => [candidateUser];

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results.length, 1);
      expect(results.first['user'], candidateUser);
      // Score calculation:
      // Interest: 1 common ('coding') / 4 * 50 = 12.5
      // Budget: same = 10
      // Location: same city, same district = 30
      // Age: 10
      // Total: 62.5 -> 63
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

      fakeFirestoreService.queryMatchingUsersStub = ({required city, limit, budgetRange}) async => [candidateUser];

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });

    test('should filter out users who fail hard filters (age)', () async {
      // Arrange
      final oldCandidate = candidateUser.copyWith(age: 40); // > maxAge 30

      fakeFirestoreService.queryMatchingUsersStub = ({required city, limit, budgetRange}) async => [oldCandidate];

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });
  });

  group('recordSwipe', () {
    test('should record swipe correctly', () async {
      // Arrange
      fakeChatService.createChatRoomStub = (u1, u2) async => 'chat_room_id';

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

      fakeChatService.createChatRoomStub = (u1, u2) async => 'chat_room_id';

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
      expect(fakeFirestoreService.updateUserStatsCalls[currentUser.uid], 1);
      expect(fakeFirestoreService.updateUserStatsCalls[candidateUser.uid], 1);

      // Verify notification sent
      expect(fakeFunctions.callable.called, true);
      expect(fakeFunctions.callable.capturedData['matchedUserId'], candidateUser.uid);
    });
  });
}

// Manual Fakes

class FakeFirestoreService extends Fake implements FirestoreService {
  Future<List<UserModel>> Function({required String city, int? limit, int? budgetRange})? queryMatchingUsersStub;
  Map<String, int> updateUserStatsCalls = {};

  @override
  Future<List<UserModel>> queryMatchingUsers({
    required String city,
    int? budgetRange,
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) async {
    if (queryMatchingUsersStub != null) {
      return queryMatchingUsersStub!(city: city, limit: limit, budgetRange: budgetRange);
    }
    return [];
  }

  @override
  Future<void> updateUserStats(String uid, {int? totalMatches, int? totalDinners}) async {
    if (totalMatches != null) {
      updateUserStatsCalls[uid] = (updateUserStatsCalls[uid] ?? 0) + totalMatches;
    }
  }
}

class FakeChatService extends Fake implements ChatService {
  Future<String> Function(String, String)? createChatRoomStub;

  @override
  Future<String> createChatRoom(String user1Id, String user2Id) async {
    if (createChatRoomStub != null) {
      return createChatRoomStub!(user1Id, user2Id);
    }
    return 'default_chat_room';
  }
}

class FakeFirebaseFunctions extends Fake implements FirebaseFunctions {
  final FakeHttpsCallable callable = FakeHttpsCallable();

  @override
  HttpsCallable httpsCallable(String? name, {HttpsCallableOptions? options}) {
    if (name == 'notifyMatch') {
      return callable;
    }
    throw UnimplementedError('Unexpected function call: $name');
  }
}

class FakeHttpsCallable extends Fake implements HttpsCallable {
  bool called = false;
  dynamic capturedData;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic data]) async {
    called = true;
    capturedData = data;
    return FakeHttpsCallableResult<T>();
  }
}

class FakeHttpsCallableResult<T> extends Fake implements HttpsCallableResult<T> {
  @override
  T get data => throw UnimplementedError();
}
