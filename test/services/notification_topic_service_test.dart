import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/notification_topic_service.dart';

// Fake implementation of FirebaseMessaging for testing
class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  final List<String> subscribedTopics = [];
  final List<String> unsubscribedTopics = [];

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    unsubscribedTopics.add(topic);
  }
}

void main() {
  late FakeFirebaseMessaging fakeMessaging;
  late NotificationTopicService service;

  setUp(() {
    NotificationTopicService.resetInstance();
    fakeMessaging = FakeFirebaseMessaging();
    service = NotificationTopicService(messaging: fakeMessaging);
  });

  group('NotificationTopicService', () {
    test('subscribeToTopic calls messaging.subscribeToTopic', () async {
      await service.subscribeToTopic('test_topic');
      expect(fakeMessaging.subscribedTopics, contains('test_topic'));
    });

    test('unsubscribeFromTopic calls messaging.unsubscribeFromTopic', () async {
      await service.unsubscribeFromTopic('test_topic');
      expect(fakeMessaging.unsubscribedTopics, contains('test_topic'));
    });

    test('getRegionTopic returns correct topic string', () {
      expect(service.getRegionTopic('Taipei'), 'region_taipei');
      expect(service.getRegionTopic('Taichung'), 'region_taichung');
      expect(service.getRegionTopic('New York'), 'region_new_york');
    });

    test('getInterestTopic returns correct topic string', () {
      expect(service.getInterestTopic('movie'), 'interest_movie');
      expect(service.getInterestTopic('hiking'), 'interest_hiking');
    });

    test('syncSubscriptions subscribes to all topics', () async {
      final topics = ['topic1', 'topic2', 'topic3'];
      await service.syncSubscriptions(topics);
      expect(fakeMessaging.subscribedTopics, containsAll(topics));
      expect(fakeMessaging.subscribedTopics.length, 3);
    });
  });
}
