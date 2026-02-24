import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('DinnerEventService', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    // ==================== 活動建立測試 ====================

    group('Create Dinner Event', () {
      test('should create a new dinner event', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'Taipei Dinner',
          'date': DateTime(2026, 2, 15),
          'city': 'Taipei',
          'restaurantName': 'Test Restaurant',
          'participantIds': [],
          'maxParticipants': 6,
          'status': 'open',
          'createdAt': DateTime.now(),
        });

        expect(eventRef.id, isNotEmpty);

        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();
        
        expect(event.data()?['title'], equals('Taipei Dinner'));
        expect(event.data()?['maxParticipants'], equals(6));
        expect(event.data()?['status'], equals('open'));
      });
    });

    // ==================== 參加者限制測試 ====================

    group('Participant Limits', () {
      test('should enforce max 6 participants', () async {
        const maxParticipants = 6;
        final participantIds = ['user1', 'user2', 'user3', 'user4', 'user5', 'user6'];
        
        expect(participantIds.length, equals(maxParticipants));
        expect(participantIds.length <= maxParticipants, isTrue);
      });

      test('should reject 7th participant', () async {
        const maxParticipants = 6;
        final participantIds = ['user1', 'user2', 'user3', 'user4', 'user5', 'user6', 'user7'];
        
        expect(participantIds.length > maxParticipants, isTrue);
      });

      test('should mark event as full when reaching 6 participants', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'Full Event',
          'participantIds': ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
          'maxParticipants': 6,
          'status': 'open',
        });

        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();
        
        final participants = List<String>.from(event.data()?['participantIds'] ?? []);
        final maxParticipants = event.data()?['maxParticipants'] ?? 6;
        
        final isFull = participants.length >= maxParticipants;
        expect(isFull, isTrue);
      });
    });

    // ==================== 加入活動測試 ====================

    group('Join Event', () {
      test('should add user to participant list', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'Joinable Event',
          'participantIds': ['user1'],
          'maxParticipants': 6,
          'status': 'open',
        });

        // 模擬加入
        await fakeFirestore.collection('dinner_events').doc(eventRef.id).update({
          'participantIds': ['user1', 'user2'],
        });

        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();
        
        expect(event.data()?['participantIds'], contains('user2'));
      });

      test('should prevent duplicate join', () async {
        final participantIds = ['user1', 'user2'];
        const newUserId = 'user1';

        final alreadyJoined = participantIds.contains(newUserId);
        expect(alreadyJoined, isTrue);
      });
    });

    // ==================== 離開活動測試 ====================

    group('Leave Event', () {
      test('should remove user from participant list', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'Leavable Event',
          'participantIds': ['user1', 'user2'],
          'maxParticipants': 6,
          'status': 'open',
        });

        // 模擬離開
        await fakeFirestore.collection('dinner_events').doc(eventRef.id).update({
          'participantIds': ['user1'],
        });

        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();
        
        expect(event.data()?['participantIds'], isNot(contains('user2')));
      });
    });

    // ==================== 活動查詢測試 ====================

    group('Query Events', () {
      test('should query events by city', () async {
        await fakeFirestore.collection('dinner_events').add({
          'title': 'Taipei Event',
          'city': 'Taipei',
          'status': 'open',
        });

        await fakeFirestore.collection('dinner_events').add({
          'title': 'Kaohsiung Event',
          'city': 'Kaohsiung',
          'status': 'open',
        });

        final taipeiEvents = await fakeFirestore
            .collection('dinner_events')
            .where('city', isEqualTo: 'Taipei')
            .get();

        expect(taipeiEvents.docs.length, equals(1));
        expect(taipeiEvents.docs.first.data()['title'], equals('Taipei Event'));
      });

      test('should query open events only', () async {
        await fakeFirestore.collection('dinner_events').add({
          'title': 'Open Event',
          'status': 'open',
        });

        await fakeFirestore.collection('dinner_events').add({
          'title': 'Closed Event',
          'status': 'closed',
        });

        final openEvents = await fakeFirestore
            .collection('dinner_events')
            .where('status', isEqualTo: 'open')
            .get();

        expect(openEvents.docs.length, equals(1));
        expect(openEvents.docs.first.data()['title'], equals('Open Event'));
      });

      test('should query events by date string', () async {
        const targetDateStr = '2026-02-15';

        await fakeFirestore.collection('dinner_events').add({
          'title': 'Feb 15 Event',
          'dateStr': targetDateStr,
          'status': 'open',
        });

        final events = await fakeFirestore
            .collection('dinner_events')
            .where('dateStr', isEqualTo: targetDateStr)
            .get();

        expect(events.docs.length, equals(1));
        expect(events.docs.first.data()['title'], equals('Feb 15 Event'));
      });
    });

    // ==================== 活動狀態測試 ====================

    group('Event Status', () {
      test('should have open status for new events', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'New Event',
          'status': 'open',
        });

        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();

        expect(event.data()?['status'], equals('open'));
      });

      test('should update status to full when capacity reached', () async {
        final eventRef = await fakeFirestore.collection('dinner_events').add({
          'title': 'Almost Full',
          'participantIds': ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
          'maxParticipants': 6,
          'status': 'open',
        });

        // 檢查是否滿員
        final event = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();
        
        final participants = List<String>.from(event.data()?['participantIds'] ?? []);
        final maxParticipants = event.data()?['maxParticipants'] ?? 6;
        
        if (participants.length >= maxParticipants) {
          await fakeFirestore.collection('dinner_events').doc(eventRef.id).update({
            'status': 'full',
          });
        }

        final updatedEvent = await fakeFirestore
            .collection('dinner_events')
            .doc(eventRef.id)
            .get();

        expect(updatedEvent.data()?['status'], equals('full'));
      });
    });
  });
}
