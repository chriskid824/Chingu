import 'package:cloud_firestore/cloud_firestore.dart';

class UserStats {
  final int matchCount;
  final int eventCount;
  final int chatCount;

  UserStats({
    required this.matchCount,
    required this.eventCount,
    required this.chatCount,
  });
}

class StatsService {
  final FirebaseFirestore _firestore;

  StatsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserStats> getUserStats(String userId, {int? currentMatchCount}) async {
    try {
      // 1. Match Count
      // If currentMatchCount is provided (from UserModel), use it.
      // Otherwise, we might need to fetch UserModel or count swipes/matches.
      // For now, if not provided, we'll try to fetch UserModel.
      int matches = currentMatchCount ?? 0;
      if (currentMatchCount == null) {
         final userDoc = await _firestore.collection('users').doc(userId).get();
         if (userDoc.exists) {
           matches = (userDoc.data()?['totalMatches'] as int?) ?? 0;
         }
      }

      // 2. Event Count
      // Count documents in 'dinner_events' where 'participantIds' contains userId
      final eventsQuery = await _firestore
          .collection('dinner_events')
          .where('participantIds', arrayContains: userId)
          .count()
          .get();
      final int events = eventsQuery.count ?? 0;

      // 3. Chat Count
      // Count documents in 'chat_rooms' where 'participantIds' contains userId
      final chatsQuery = await _firestore
          .collection('chat_rooms')
          .where('participantIds', arrayContains: userId)
          .count()
          .get();
      final int chats = chatsQuery.count ?? 0;

      return UserStats(
        matchCount: matches,
        eventCount: events,
        chatCount: chats,
      );
    } catch (e) {
      print('StatsService.getUserStats error: $e');
      // Return zeros on error or rethrow? Let's return zeros for UI stability.
      return UserStats(matchCount: 0, eventCount: 0, chatCount: 0);
    }
  }
}
