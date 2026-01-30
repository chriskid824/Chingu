import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/topic_subscription_service.dart';

@GenerateNiceMocks([MockSpec<FirebaseMessaging>()])
import 'topic_subscription_service_test.mocks.dart';

void main() {
  group('TopicSubscriptionService', () {
    late TopicSubscriptionService service;
    late MockFirebaseMessaging mockMessaging;

    setUp(() {
      mockMessaging = MockFirebaseMessaging();
      service = TopicSubscriptionService();
      service.messaging = mockMessaging;
    });

    test('subscribeToTopic calls messaging.subscribeToTopic', () async {
      await service.subscribeToTopic('test_topic');
      verify(mockMessaging.subscribeToTopic('test_topic')).called(1);
    });

    test('unsubscribeFromTopic calls messaging.unsubscribeFromTopic', () async {
      await service.unsubscribeFromTopic('test_topic');
      verify(mockMessaging.unsubscribeFromTopic('test_topic')).called(1);
    });

    test('updateRegionSubscriptions subscribes to new and unsubscribes from old', () async {
      final oldRegions = ['taipei'];
      final newRegions = ['taichung'];

      await service.updateRegionSubscriptions(oldRegions, newRegions);

      // Should unsubscribe from region_taipei
      verify(mockMessaging.unsubscribeFromTopic('region_taipei')).called(1);
      // Should subscribe to region_taichung
      verify(mockMessaging.subscribeToTopic('region_taichung')).called(1);
    });

    test('updateInterestSubscriptions subscribes to new and unsubscribes from old', () async {
      // '電影' maps to 'movie' -> topic 'interest_movie'
      // '音樂' maps to 'music' -> topic 'interest_music'
      final oldInterests = ['電影'];
      final newInterests = ['音樂'];

      await service.updateInterestSubscriptions(oldInterests, newInterests);

      verify(mockMessaging.unsubscribeFromTopic('interest_movie')).called(1);
      verify(mockMessaging.subscribeToTopic('interest_music')).called(1);
    });
  });
}
