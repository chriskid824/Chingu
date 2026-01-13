import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/matching_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake implementation to replace Mockito
class FakeFirestoreService implements FirestoreService {
  List<UserModel> _queryResult = [];

  void setQueryResult(List<UserModel> users) {
    _queryResult = users;
  }

  @override
  Future<List<UserModel>> queryMatchingUsers({
    required String city,
    int? budgetRange,
    String? gender,
    int? minAge,
    int? maxAge,
    int limit = 20,
  }) async {
    return _queryResult;
  }

  // Implement other methods as throws or dummy
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChatService implements ChatService {
  @override
  Future<String> createChatRoom(String user1Id, String user2Id) async {
    return 'fake_chat_room';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MatchingService matchingService;
  late FakeFirestoreService fakeFirestoreService;
  late FakeChatService fakeChatService;
  late FakeFirebaseFirestore fakeFirestore;

  // Test data
  final currentUser = UserModel(
    uid: 'current_user',
    email: 'current@test.com',
    name: 'Current User',
    gender: 'male',
    job: 'Developer',
    preferredMatchType: 'any',
    country: 'Taiwan',
    city: 'Taipei',
    district: 'Xinyi',
    budgetRange: 2,
    interests: ['coding', 'reading'],
    minAge: 20,
    maxAge: 30,
    age: 25,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );

  final candidateUser = UserModel(
    uid: 'candidate_user',
    email: 'candidate@test.com',
    name: 'Candidate User',
    gender: 'female',
    job: 'Designer',
    preferredMatchType: 'any',
    country: 'Taiwan',
    city: 'Taipei',
    district: 'Xinyi',
    budgetRange: 2,
    interests: ['coding', 'movies'],
    minAge: 20,
    maxAge: 30,
    age: 24,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
  );

  setUp(() {
    fakeFirestoreService = FakeFirestoreService();
    fakeChatService = FakeChatService();
    fakeFirestore = FakeFirebaseFirestore();

    matchingService = MatchingService(
      firestore: fakeFirestore,
      firestoreService: fakeFirestoreService,
      chatService: fakeChatService,
    );
  });

  group('MatchingService Blocking Logic', () {
    test('should filter out blocked users', () async {
      // Current user blocked candidate
      final blockingUser = currentUser.copyWith(blockedUsers: [candidateUser.uid]);

      // Fake query to return candidate
      fakeFirestoreService.setQueryResult([candidateUser]);

      // Act
      final results = await matchingService.getMatches(blockingUser);

      // Assert
      expect(results, isEmpty);
    });

    test('should filter out users who blocked current user', () async {
      // Candidate blocked current user
      final blockingCandidate = candidateUser.copyWith(blockedUsers: [currentUser.uid]);

      // Fake query to return blocking candidate
      fakeFirestoreService.setQueryResult([blockingCandidate]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results, isEmpty);
    });

    test('should return candidate if no blocking exists', () async {
      // Fake query to return candidate
      fakeFirestoreService.setQueryResult([candidateUser]);

      // Act
      final results = await matchingService.getMatches(currentUser);

      // Assert
      expect(results.length, 1);
      expect(results.first['user'].uid, candidateUser.uid);
    });
  });
}
