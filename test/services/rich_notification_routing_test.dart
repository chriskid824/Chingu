import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/core/routes/app_router.dart';

void main() {
  group('RichNotificationService.resolveRoute', () {
    test('resolves chat deeplink correctly', () {
      final result = RichNotificationService.resolveRoute('chingu://chat/123', null, null);
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.chatDetail);
      expect(result['args'], {'chatRoomId': '123'});
    });

    test('resolves event deeplink correctly', () {
      final result = RichNotificationService.resolveRoute('chingu://event/456', null, null);
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.eventDetail);
      expect(result['args'], {'eventId': '456'});
    });

    test('resolves user deeplink correctly', () {
      final result = RichNotificationService.resolveRoute('chingu://user/789', null, null);
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.userDetail);
      expect(result['args'], {'userId': '789'});
    });

    test('resolves match_detail deeplink correctly', () {
      final result = RichNotificationService.resolveRoute('chingu://match_detail/789', null, null);
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.userDetail);
      expect(result['args'], {'userId': '789'});
    });

    test('prioritizes deeplink over actionType', () {
      final result = RichNotificationService.resolveRoute('chingu://chat/123', 'view_event', '456');
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.chatDetail); // Should be chatDetail
    });

    test('falls back to actionType open_chat', () {
      final result = RichNotificationService.resolveRoute(null, 'open_chat', '123');
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.chatDetail);
      expect(result['args'], {'chatRoomId': '123'});
    });

    test('falls back to actionType view_event', () {
      final result = RichNotificationService.resolveRoute(null, 'view_event', '456');
      expect(result, isNotNull);
      expect(result!['route'], AppRoutes.eventDetail);
      expect(result['args'], {'eventId': '456'});
    });

    test('returns null for invalid input', () {
      final result = RichNotificationService.resolveRoute(null, null, null);
      expect(result, isNull);
    });

    test('returns null for invalid scheme', () {
      final result = RichNotificationService.resolveRoute('https://google.com', null, null);
      expect(result, isNull);
    });
  });
}
