import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/services/notification_ab_service.dart';
import 'package:chingu/models/notification_model.dart';
import 'package:chingu/services/notification_storage_service.dart';

// Since NotificationService relies on singletons and external services,
// we might need to mock them or use dependency injection.
// However, NotificationService instantiates them internally.
// But NotificationABService accepts a firestore instance in constructor now.
// We can test NotificationABService independently first.

void main() {
  group('NotificationABService Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late NotificationABService abService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      abService = NotificationABService(firestore: fakeFirestore);
    });

    test('trackNotificationSent adds document to notification_stats', () async {
      await abService.trackNotificationSent('user1', 'notif1', NotificationType.match);

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], 'user1');
      expect(data['notificationId'], 'notif1');
      expect(data['type'], 'match');
      expect(data['event'], 'sent');
      // Verify group assignment logic
      // hash('user1') determines group.
      final group = abService.getGroup('user1');
      expect(data['group'], group.toString().split('.').last);
    });

    test('trackNotificationClicked adds document to notification_stats', () async {
      await abService.trackNotificationClicked('user1', 'notif1', NotificationType.match);

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], 'user1');
      expect(data['notificationId'], 'notif1');
      expect(data['type'], 'match');
      expect(data['event'], 'clicked');
    });

    test('getContent returns different content for different groups', () {
        // Find users that hash to different groups
        String userA = 'user_control'; // Need to find one that maps to control
        String userB = 'user_variant'; // Need to find one that maps to variant

        // Let's brute force find them for the test to be robust against hash implementation details
        int i = 0;
        while(abService.getGroup('user_$i') != ExperimentGroup.control) i++;
        userA = 'user_$i';

        i = 0;
        while(abService.getGroup('user_$i') != ExperimentGroup.variant) i++;
        userB = 'user_$i';

        final contentA = abService.getContent(userA, NotificationType.match, params: {'partnerName': 'Alice'});
        final contentB = abService.getContent(userB, NotificationType.match, params: {'partnerName': 'Alice'});

        expect(contentA.title, isNot(contentB.title));
        expect(contentA.body, isNot(contentB.body));
    });
  });
}
