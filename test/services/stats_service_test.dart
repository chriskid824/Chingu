import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/stats_service.dart';

void main() {
  group('StatsService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late StatsService statsService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      statsService = StatsService(firestore: fakeFirestore);
    });

    test('getUserStats returns correct counts', () async {
      const userId = 'user1';

      // Setup data
      // 1. User
      await fakeFirestore.collection('users').doc(userId).set({
        'totalMatches': 5,
      });

      // 2. Events (User is participant in 2 events)
      await fakeFirestore.collection('dinner_events').add({
        'participantIds': [userId, 'user2'],
      });
      await fakeFirestore.collection('dinner_events').add({
        'participantIds': [userId, 'user3'],
      });
      await fakeFirestore.collection('dinner_events').add({
        'participantIds': ['user2', 'user3'], // Not participant
      });

      // 3. Chats (User is participant in 3 chats)
      await fakeFirestore.collection('chat_rooms').add({
        'participantIds': [userId, 'user2'],
      });
      await fakeFirestore.collection('chat_rooms').add({
        'participantIds': [userId, 'user3'],
      });
      await fakeFirestore.collection('chat_rooms').add({
        'participantIds': [userId, 'user4'],
      });
      await fakeFirestore.collection('chat_rooms').add({
        'participantIds': ['user5', 'user6'], // Not participant
      });

      // Execute
      final stats = await statsService.getUserStats(userId);

      // Verify
      expect(stats.matchCount, 5); // From user doc
      expect(stats.eventCount, 2);
      expect(stats.chatCount, 3);
    });

    test('getUserStats uses provided currentMatchCount', () async {
      const userId = 'user1';
      // User doc has 5, but we pass 10
      await fakeFirestore.collection('users').doc(userId).set({
        'totalMatches': 5,
      });

      final stats = await statsService.getUserStats(userId, currentMatchCount: 10);

      expect(stats.matchCount, 10);
    });
  });
}
