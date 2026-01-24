import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/providers/dinner_event_provider.dart';
import 'package:chingu/services/dinner_event_service.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Mock class
class MockDinnerEventService implements DinnerEventService {
  final List<DinnerEventModel> _mockEvents = [];
  bool shouldThrow = false;
  List<DateTime> mockThursdayDates = [];

  // Helper method to reset state
  void reset() {
    _mockEvents.clear();
    shouldThrow = false;
    mockThursdayDates.clear();
  }

  @override
  Future<String> createEvent({
    required String creatorId,
    required DateTime dateTime,
    required int budgetRange,
    required String city,
    required String district,
    String? notes,
  }) async {
    if (shouldThrow) throw Exception('Mock Error');
    final event = DinnerEventModel(
      id: 'mock_id_${_mockEvents.length}',
      creatorId: creatorId,
      dateTime: dateTime,
      budgetRange: budgetRange,
      city: city,
      district: district,
      notes: notes,
      participantIds: [creatorId],
      participantStatus: {creatorId: 'confirmed'},
      createdAt: DateTime.now(),
    );
    _mockEvents.add(event);
    return event.id;
  }

  @override
  Future<DinnerEventModel?> getEvent(String eventId) async {
    if (shouldThrow) throw Exception('Mock Error');
    try {
      return _mockEvents.firstWhere((e) => e.id == eventId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<DinnerEventModel>> getUserEvents(String userId, {EventStatus? status}) async {
    if (shouldThrow) throw Exception('Mock Error');
    return _mockEvents.where((e) {
      final matchesUser = e.participantIds.contains(userId);
      if (status != null) {
        return matchesUser && e.status == status;
      }
      return matchesUser;
    }).toList();
  }

  @override
  Future<void> registerForEvent(String eventId, String userId) async {
    if (shouldThrow) throw Exception('Mock Error');
    final index = _mockEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _mockEvents[index];
      final newParticipants = List<String>.from(event.participantIds)..add(userId);
      final newStatus = Map<String, String>.from(event.participantStatus)..[userId] = 'confirmed';
      _mockEvents[index] = event.copyWith(
        participantIds: newParticipants,
        participantStatus: newStatus,
      );
    }
  }

  @override
  Future<void> unregisterFromEvent(String eventId, String userId) async {
    if (shouldThrow) throw Exception('Mock Error');
    final index = _mockEvents.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final event = _mockEvents[index];
      final newParticipants = List<String>.from(event.participantIds)..remove(userId);
      final newStatus = Map<String, String>.from(event.participantStatus)..remove(userId);
      _mockEvents[index] = event.copyWith(
        participantIds: newParticipants,
        participantStatus: newStatus,
      );
    }
  }

  // Keeping these for backward compatibility/interface compliance if not removed yet,
  // or implementing as alias to new methods if interface requires them.
  // Assuming strict interface match to DinnerEventService which may not have these anymore or uses them.
  // Since I didn't remove them from Service (I might have if I followed strict plan), but usually I keep them.
  // Let's check Service. I didn't remove them explicitly in previous steps, just added new ones.
  // Wait, I saw "Deprecated methods" in my write_file for service.
  // If I kept them in service, I must keep them here.

  // Actually, I wrote the file completely, let's check if I kept joinEvent/leaveEvent in Service.
  // I did NOT keep them in the write_file of DinnerEventService. I replaced them with comments saying "Deprecated...".
  // Wait, I should double check `lib/services/dinner_event_service.dart`.

  @override
  Future<List<DinnerEventModel>> getRecommendedEvents({
    required String city,
    required int budgetRange,
    List<String> excludeEventIds = const [],
  }) async {
    if (shouldThrow) throw Exception('Mock Error');
    return _mockEvents.where((e) =>
      e.city == city &&
      e.budgetRange == budgetRange &&
      !excludeEventIds.contains(e.id)
    ).toList();
  }

  @override
  Stream<DinnerEventModel?> getEventStream(String eventId) {
    throw UnimplementedError();
  }

  @override
  List<DateTime> getThursdayDates() {
    if (mockThursdayDates.isNotEmpty) return mockThursdayDates;
    // Default fallback if not set
    return [
      DateTime.now().add(const Duration(days: 7)),
      DateTime.now().add(const Duration(days: 14)),
    ];
  }

  @override
  Future<String> joinOrCreateEvent({
    required String userId,
    required DateTime date,
    required String city,
    required String district,
  }) async {
    if (shouldThrow) throw Exception('Mock Error');
    // For simplicity, just create a new one in mock
    return createEvent(
        creatorId: userId,
        dateTime: date,
        budgetRange: 1,
        city: city,
        district: district
    );
  }
}

void main() {
  group('DinnerEventProvider Tests', () {
    late DinnerEventProvider provider;
    late MockDinnerEventService mockService;

    setUp(() {
      mockService = MockDinnerEventService();
      provider = DinnerEventProvider(dinnerEventService: mockService);
    });

    test('Initial state is correct', () {
      expect(provider.myEvents, isEmpty);
      expect(provider.recommendedEvents, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('createEvent success', () async {
      final success = await provider.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(success, isTrue);
      expect(provider.myEvents.length, 1);
      expect(provider.myEvents.first.creatorId, 'user1');
      expect(provider.isLoading, isFalse);
    });

    test('createEvent failure', () async {
      mockService.shouldThrow = true;
      final success = await provider.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('Mock Error'));
      expect(provider.isLoading, isFalse);
    });

    test('fetchMyEvents success', () async {
      // Pre-populate mock service
      await mockService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await provider.fetchMyEvents('user1');
      expect(provider.myEvents.length, 1);
      expect(provider.myEvents.first.creatorId, 'user1');
    });

    test('fetchRecommendedEvents success', () async {
       // Pre-populate mock service with matching event
      await mockService.createEvent(
        creatorId: 'user2', // Different user
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      await provider.fetchRecommendedEvents(city: 'Taipei', budgetRange: 1);
      expect(provider.recommendedEvents.length, 1);
    });

    test('joinEvent success', () async {
       // Pre-populate mock service
      final eventId = await mockService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );

      final success = await provider.joinEvent(eventId, 'user2');
      expect(success, isTrue);

      // Verify user2 sees the event now
      await provider.fetchMyEvents('user2');
      expect(provider.myEvents.length, 1);
      expect(provider.myEvents.first.participantIds, contains('user2'));
    });

    test('leaveEvent success', () async {
       // Pre-populate mock service and join
      final eventId = await mockService.createEvent(
        creatorId: 'user1',
        dateTime: DateTime.now(),
        budgetRange: 1,
        city: 'Taipei',
        district: 'Xinyi',
      );
      await mockService.registerForEvent(eventId, 'user2');

      final success = await provider.leaveEvent(eventId, 'user2');
      expect(success, isTrue);

      // Verify user2 does not see the event anymore
      await provider.fetchMyEvents('user2');
      expect(provider.myEvents, isEmpty);
    });

    test('bookEvent success', () async {
      final success = await provider.bookEvent(
        userId: 'user1',
        date: DateTime.now(),
        city: 'Taipei',
        district: 'Xinyi',
      );

      expect(success, isTrue);
      expect(provider.myEvents.length, 1);
    });

    test('getBookableDates returns valid dates', () {
       // Set dates far in future so they are definitely bookable
       final date1 = DateTime.now().add(const Duration(days: 100));
       final date2 = DateTime.now().add(const Duration(days: 107));
       mockService.mockThursdayDates = [date1, date2];

       final dates = provider.getBookableDates();
       expect(dates.length, 2);
    });

    test('getBookableDates filters out joined dates', () async {
       final date1 = DateTime.now().add(const Duration(days: 100)); // Future
       mockService.mockThursdayDates = [date1];

       // Add an event on date1 to myEvents
       await mockService.createEvent(
         creatorId: 'user1',
         dateTime: date1,
         budgetRange: 1,
         city: 'City',
         district: 'Dist',
       );
       await provider.fetchMyEvents('user1');

       // Now getBookableDates should return empty
       final dates = provider.getBookableDates();
       expect(dates, isEmpty);
    });
  });
}
