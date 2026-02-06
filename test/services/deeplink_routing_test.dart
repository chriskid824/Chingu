import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/core/routes/app_routes.dart';

void main() {
  group('RichNotificationService Deeplink Routing', () {
    final service = RichNotificationService();

    test('match_success should route to ChatDetail with correct args', () {
      final data = {
        'notification_type': 'match_success',
        'chatRoomId': 'chat_123',
        'matchedUserId': 'user_456',
      };

      final routeInfo = service.getRouteInfo(data);

      expect(routeInfo, isNotNull);
      expect(routeInfo!.routeName, AppRoutes.chatDetail);
      final args = routeInfo.arguments as Map<String, dynamic>;
      expect(args['chatRoomId'], 'chat_123');
      expect(args['otherUserId'], 'user_456');
    });

    test('new_message should route to ChatDetail with senderId as otherUserId', () {
      final data = {
        'notification_type': 'new_message',
        'chatId': 'chat_789',
        'senderId': 'user_999',
      };

      final routeInfo = service.getRouteInfo(data);

      expect(routeInfo, isNotNull);
      expect(routeInfo!.routeName, AppRoutes.chatDetail);
      final args = routeInfo.arguments as Map<String, dynamic>;
      expect(args['chatRoomId'], 'chat_789');
      expect(args['otherUserId'], 'user_999');
    });

    test('dinner_event should route to EventDetail with eventId', () {
      final data = {
        'type': 'dinner_event',
        'eventId': 'event_001',
      };

      final routeInfo = service.getRouteInfo(data);

      expect(routeInfo, isNotNull);
      expect(routeInfo!.routeName, AppRoutes.eventDetail);
      final args = routeInfo.arguments as Map<String, dynamic>;
      expect(args['eventId'], 'event_001');
    });

    test('legacy actionType open_chat should route to ChatList', () {
      final data = {
        'actionType': 'open_chat',
      };

      final routeInfo = service.getRouteInfo(data);

      expect(routeInfo, isNotNull);
      expect(routeInfo!.routeName, AppRoutes.chatList);
    });

    test('unknown type should return null (fallback to default)', () {
      final data = {
        'type': 'unknown_thing',
      };

      final routeInfo = service.getRouteInfo(data);

      expect(routeInfo, isNull);
    });
  });
}
