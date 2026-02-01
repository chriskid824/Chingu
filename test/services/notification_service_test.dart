import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service_test.mocks.dart';

@GenerateMocks([FirebaseMessaging])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NotificationService notificationService;
  late MockFirebaseMessaging mockFirebaseMessaging;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockFirebaseMessaging = MockFirebaseMessaging();
    notificationService = NotificationService();
    notificationService.setFirebaseMessagingForTesting(mockFirebaseMessaging);
  });

  UserModel createUser({required String city, required List<String> interests}) {
    return UserModel(
      uid: 'test_uid',
      name: 'Test User',
      email: 'test@example.com',
      age: 25,
      gender: 'male',
      job: 'Developer',
      interests: interests,
      country: 'Taiwan',
      city: city,
      district: 'District',
      preferredMatchType: 'any',
      minAge: 18,
      maxAge: 30,
      budgetRange: 1,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  test('subscribeToTopics subscribes to region and interests', () async {
    final user = createUser(city: 'Taipei', interests: ['Hiking', 'Coding']);

    await notificationService.subscribeToTopics(user);

    verify(mockFirebaseMessaging.subscribeToTopic('topic_region_taipei')).called(1);
    verify(mockFirebaseMessaging.subscribeToTopic('topic_interest_hiking')).called(1);
    verify(mockFirebaseMessaging.subscribeToTopic('topic_interest_coding')).called(1);
  });

  test('subscribeToTopics unsubscribes from old topics', () async {
    // 1. Initial subscription
    final user1 = createUser(city: 'Taipei', interests: ['Hiking']);
    await notificationService.subscribeToTopics(user1);

    // Reset mocks to clear verification counts
    reset(mockFirebaseMessaging);

    // 2. Update user (Change city to Taichung, change interest to Cooking)
    final user2 = createUser(city: 'Taichung', interests: ['Cooking']);
    await notificationService.subscribeToTopics(user2);

    // Should unsubscribe from Taipei and Hiking
    verify(mockFirebaseMessaging.unsubscribeFromTopic('topic_region_taipei')).called(1);
    verify(mockFirebaseMessaging.unsubscribeFromTopic('topic_interest_hiking')).called(1);

    // Should subscribe to Taichung and Cooking
    verify(mockFirebaseMessaging.subscribeToTopic('topic_region_taichung')).called(1);
    verify(mockFirebaseMessaging.subscribeToTopic('topic_interest_cooking')).called(1);
  });

  test('subscribeToTopics handles Chinese city names', () async {
    final user = createUser(city: '台北市', interests: []);
    await notificationService.subscribeToTopics(user);
    verify(mockFirebaseMessaging.subscribeToTopic('topic_region_taipei')).called(1);

    final user2 = createUser(city: '高雄市', interests: []);
    await notificationService.subscribeToTopics(user2);
    verify(mockFirebaseMessaging.subscribeToTopic('topic_region_kaohsiung')).called(1);
  });
}
