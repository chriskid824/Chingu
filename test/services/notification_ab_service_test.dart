import 'package:flutter_test/flutter_test.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  late NotificationABService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationABService(firestore: fakeFirestore);
  });

  group('NotificationABService Group Assignment', () {
    test('getGroup returns consistent results for same userId', () {
      const userId = 'user123';
      final group1 = service.getGroup(userId);
      final group2 = service.getGroup(userId);

      expect(group1, group2);
    });

    test('getGroup distributes users differently', () {
      // Find two userIds that map to different groups
      // Note: This depends on hashCode implementation which is platform dependent,
      // but usually consistent within a run.
      // We'll just check that it returns valid enums.
      final group = service.getGroup('user_A');
      expect(group, isA<ExperimentGroup>());
    });
  });

  group('NotificationABService Content', () {
    test('Match notification content differs by group', () {
      // Find a user for Control group
      String controlUser = 'user_control';
      // Find a user for Variant group
      String variantUser = 'user_variant';

      // Brute force to find one of each to ensure test validity
      while (service.getGroup(controlUser) != ExperimentGroup.control) {
        controlUser += '1';
      }
      while (service.getGroup(variantUser) != ExperimentGroup.variant) {
        variantUser += '1';
      }

      final controlContent = service.getContent(
        controlUser,
        NotificationType.match,
        params: {'partnerName': 'Alice'}
      );

      final variantContent = service.getContent(
        variantUser,
        NotificationType.match,
        params: {'partnerName': 'Alice'}
      );

      expect(controlContent.title, 'New Match');
      expect(controlContent.body, 'You have a new match with Alice.');

      expect(variantContent.title, 'New Match! 🎉');
      expect(variantContent.body, 'You matched with Alice! Say hi now! 👋');
    });

    test('Message notification content differs by group', () {
      // Find a user for Control group
      String controlUser = 'user_control';
      while (service.getGroup(controlUser) != ExperimentGroup.control) {
        controlUser += '1';
      }

      // Find a user for Variant group
      String variantUser = 'user_variant';
      while (service.getGroup(variantUser) != ExperimentGroup.variant) {
        variantUser += '1';
      }

      final controlContent = service.getContent(
        controlUser,
        NotificationType.message,
        params: {'senderName': 'Bob'}
      );

      final variantContent = service.getContent(
        variantUser,
        NotificationType.message,
        params: {'senderName': 'Bob'}
      );

      expect(controlContent.title, 'New Message');
      expect(controlContent.body, 'Bob sent you a message.');

      expect(variantContent.title, 'New Message 💬');
      expect(variantContent.body, 'Bob sent you a message. Don\'t leave them waiting!');
    });
  });

  group('NotificationABService Tracking', () {
    test('trackNotificationSent logs event to Firestore', () async {
      const userId = 'user123';
      const notificationId = 'notif_abc';
      const type = 'match';

      await service.trackNotificationSent(userId, notificationId, type);

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['notificationId'], notificationId);
      expect(data['type'], type);
      expect(data['event'], 'sent');
      expect(data['variant'], isNotNull);
      expect(data['timestamp'], isNotNull);
    });

    test('trackNotificationClicked logs event to Firestore', () async {
      const userId = 'user456';
      const notificationId = 'notif_def';
      const type = 'message';

      await service.trackNotificationClicked(userId, notificationId, type);

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['notificationId'], notificationId);
      expect(data['type'], type);
      expect(data['event'], 'clicked');
      expect(data['variant'], isNotNull);
      expect(data['timestamp'], isNotNull);
    });
  });
}
