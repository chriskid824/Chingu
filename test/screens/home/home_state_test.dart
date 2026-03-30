import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/screens/home/home_state.dart';
import 'package:chingu/models/dinner_event_model.dart';
import 'package:chingu/models/dinner_group_model.dart';

void main() {
  const userId = 'test-user-123';

  DinnerEventModel _makeEvent({
    required String id,
    required DateTime eventDate,
    String status = 'open',
  }) {
    return DinnerEventModel(
      id: id,
      eventDate: eventDate,
      signupDeadline: eventDate.subtract(const Duration(days: 2)),
      status: status,
      city: '台北市',
      signedUpUsers: [userId],
      createdAt: DateTime.now(),
    );
  }

  DinnerGroupModel _makeGroup({
    required String id,
    required String status,
    String reviewStatus = 'none',
    List<String>? participantIds,
  }) {
    return DinnerGroupModel(
      id: id,
      eventId: 'event-1',
      participantIds: participantIds ?? [userId, 'u2', 'u3', 'u4', 'u5', 'u6'],
      status: status,
      reviewStatus: reviewStatus,
      createdAt: DateTime.now(),
    );
  }

  group('HomeStateResolver', () {
    test('沒有活動也沒有群組 → notSignedUp', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [],
        userId: userId,
      );
      expect(result.state, HomeState.notSignedUp);
    });

    test('有未來活動但沒有群組 → matching', () {
      final result = HomeStateResolver.resolve(
        myEvents: [
          _makeEvent(
            id: 'e1',
            eventDate: DateTime.now().add(const Duration(days: 3)),
          ),
        ],
        myGroups: [],
        userId: userId,
      );
      expect(result.state, HomeState.matching);
      expect(result.event, isNotNull);
    });

    test('有 pending 群組 → matching', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [_makeGroup(id: 'g1', status: 'pending')],
        userId: userId,
      );
      expect(result.state, HomeState.matching);
      expect(result.group, isNotNull);
    });

    test('有 info_revealed 群組 → partialReveal', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [_makeGroup(id: 'g1', status: 'info_revealed')],
        userId: userId,
      );
      expect(result.state, HomeState.partialReveal);
      expect(result.group!.status, 'info_revealed');
    });

    test('有 location_revealed 群組 → fullReveal', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [_makeGroup(id: 'g1', status: 'location_revealed')],
        userId: userId,
      );
      expect(result.state, HomeState.fullReveal);
    });

    test('有 completed + reviewStatus none 群組 → pendingReview', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [
          _makeGroup(id: 'g1', status: 'completed', reviewStatus: 'none'),
        ],
        userId: userId,
      );
      expect(result.state, HomeState.pendingReview);
      expect(result.group!.id, 'g1');
    });

    test('pendingReview 優先於 activeGroup', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [
          _makeGroup(id: 'g1', status: 'completed', reviewStatus: 'none'),
          _makeGroup(id: 'g2', status: 'info_revealed'),
        ],
        userId: userId,
      );
      expect(result.state, HomeState.pendingReview);
      expect(result.group!.id, 'g1');
    });

    test('reviewStatus completed 不觸發 pendingReview', () {
      final result = HomeStateResolver.resolve(
        myEvents: [],
        myGroups: [
          _makeGroup(id: 'g1', status: 'completed', reviewStatus: 'completed'),
        ],
        userId: userId,
      );
      // 沒有活躍群組，沒有未來活動 → notSignedUp
      expect(result.state, HomeState.notSignedUp);
    });

    test('只有已過期活動且沒有群組 → notSignedUp', () {
      final result = HomeStateResolver.resolve(
        myEvents: [
          _makeEvent(
            id: 'e1',
            eventDate: DateTime.now().subtract(const Duration(days: 3)),
            status: 'completed',
          ),
        ],
        myGroups: [],
        userId: userId,
      );
      expect(result.state, HomeState.notSignedUp);
    });
  });
}
