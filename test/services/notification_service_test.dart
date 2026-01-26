import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseMessaging, FirestoreService])
import 'notification_service_test.mocks.dart';

void main() {
  late NotificationService notificationService;
  late MockFirebaseMessaging mockMessaging;
  late MockFirestoreService mockFirestoreService;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockFirestoreService = MockFirestoreService();
    notificationService = NotificationService(
      messaging: mockMessaging,
      firestoreService: mockFirestoreService,
    );
  });

  group('NotificationService', () {
    test('initialize requests permission', () async {
      // Arrange
      when(mockMessaging.requestPermission(
        alert: anyNamed('alert'),
        announcement: anyNamed('announcement'),
        badge: anyNamed('badge'),
        carPlay: anyNamed('carPlay'),
        criticalAlert: anyNamed('criticalAlert'),
        provisional: anyNamed('provisional'),
        sound: anyNamed('sound'),
      )).thenAnswer((_) async => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.authorized,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.enabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.enabled,
            lockScreen: AppleNotificationSetting.enabled,
            notificationCenter: AppleNotificationSetting.enabled,
            showPreviews: AppleShowPreviewSetting.always,
            sound: AppleNotificationSetting.enabled,
            criticalAlert: AppleNotificationSetting.enabled,
            timeSensitive: AppleNotificationSetting.enabled,
            providesAppNotificationSettings: AppleNotificationSetting.enabled,
          ));

      // Act
      await notificationService.initialize();

      // Assert
      verify(mockMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      )).called(1);
    });

    test('getToken returns token from messaging', () async {
      // Arrange
      when(mockMessaging.getToken()).thenAnswer((_) async => 'test_token');

      // Act
      final token = await notificationService.getToken();

      // Assert
      expect(token, 'test_token');
      verify(mockMessaging.getToken()).called(1);
    });

    test('registerToken gets token and updates firestore', () async {
      // Arrange
      when(mockMessaging.getToken()).thenAnswer((_) async => 'test_token');
      when(mockFirestoreService.updateUser(any, any))
          .thenAnswer((_) async => Future.value());

      // Act
      await notificationService.registerToken('user_123');

      // Assert
      verify(mockMessaging.getToken()).called(1);
      verify(mockFirestoreService.updateUser('user_123', {'fcmToken': 'test_token'}))
          .called(1);
    });

    test('monitorTokenRefresh listens to stream and updates firestore', () async {
      // Arrange
      // Create a stream for token refresh
      final stream = Stream<String>.fromIterable(['new_token']);
      when(mockMessaging.onTokenRefresh).thenAnswer((_) => stream);
      when(mockFirestoreService.updateUser(any, any))
          .thenAnswer((_) async => Future.value());

      // Act
      notificationService.monitorTokenRefresh('user_123');

      // Wait for stream to emit
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockFirestoreService.updateUser('user_123', {'fcmToken': 'new_token'}))
          .called(1);
    });
  });
}
