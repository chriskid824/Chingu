// Mocks generated manually since build_runner is not available
import 'package:mockito/mockito.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/chat_service.dart';
import 'package:chingu/services/user_block_service.dart';
import 'package:chingu/models/user_model.dart';

class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<List<UserModel>> queryMatchingUsers({
    required String? city,
    int? budgetRange,
    String? gender,
    int? minAge,
    int? maxAge,
    int? limit = 20,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #queryMatchingUsers,
        [],
        {
          #city: city,
          #budgetRange: budgetRange,
          #gender: gender,
          #minAge: minAge,
          #maxAge: maxAge,
          #limit: limit,
        },
      ),
      returnValue: Future.value(<UserModel>[]),
    ) as Future<List<UserModel>>;
  }

  @override
  Future<void> updateUserStats(
    String? uid, {
    int? totalDinners,
    int? totalMatches,
  }) {
    return super.noSuchMethod(
      Invocation.method(
        #updateUserStats,
        [uid],
        {#totalDinners: totalDinners, #totalMatches: totalMatches},
      ),
      returnValue: Future.value(),
    ) as Future<void>;
  }
}

class MockChatService extends Mock implements ChatService {
  @override
  Future<String> createChatRoom(String? user1Id, String? user2Id) {
    return super.noSuchMethod(
      Invocation.method(#createChatRoom, [user1Id, user2Id]),
      returnValue: Future.value(''),
    ) as Future<String>;
  }
}

class MockUserBlockService extends Mock implements UserBlockService {
  @override
  Future<List<String>> getBlockedUserIds(String? currentUserId) {
    return super.noSuchMethod(
      Invocation.method(#getBlockedUserIds, [currentUserId]),
      returnValue: Future.value(<String>[]),
    ) as Future<List<String>>;
  }
}
