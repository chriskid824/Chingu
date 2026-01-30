import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:chingu/services/notification_ab_service.dart';

void main() {
  late NotificationABService service;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = NotificationABService(firestore: fakeFirestore);
  });

  group('NotificationABService Tracking', () {
    test('trackSend logs event to Firestore', () async {
      await service.trackSend('user1', 'match', 'variant');

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], 'user1');
      expect(data['type'], 'match');
      expect(data['variant'], 'variant');
      expect(data['action'], 'send');
      expect(data['timestamp'], isNotNull);
    });

    test('trackClick logs event to Firestore', () async {
      await service.trackClick('user2', 'message', 'control');

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], 'user2');
      expect(data['type'], 'message');
      expect(data['variant'], 'control');
      expect(data['action'], 'click');
      expect(data['timestamp'], isNotNull);
    });
  });
}
