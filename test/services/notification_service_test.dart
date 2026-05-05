import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mocks
@GenerateMocks([FirebaseMessaging, FirestoreService])
import 'notification_service_test.mocks.dart';

void main() {
  group('NotificationService Tests', () {
    late MockFirebaseMessaging mockFirebaseMessaging;
    late MockFirestoreService mockFirestoreService;
    late NotificationService notificationService;

    setUp(() {
      mockFirebaseMessaging = MockFirebaseMessaging();
      mockFirestoreService = MockFirestoreService();

      notificationService = NotificationService(
        firestoreService: mockFirestoreService,
        firebaseMessaging: mockFirebaseMessaging,
      );
    });

    test('initialize requests permission and updates token', () async {
      // Arrange
      const userId = 'test-user-id';
      const token = 'test-fcm-token';

      when(mockFirebaseMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
        provisional: anyNamed('provisional'),
      )).thenAnswer((_) async => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.authorized,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.enabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.enabled,
            lockScreen: AppleNotificationSetting.enabled,
            notificationCenter: AppleNotificationSetting.enabled,
            showPreviews: AppleShowPreviewsSetting.always,
            sound: AppleNotificationSetting.enabled,
            timeSensitive: AppleNotificationSetting.enabled,
          ));

      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => token);
      when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => Stream.fromIterable([]));
      when(mockFirestoreService.updateFcmToken(any, any)).thenAnswer((_) async {});

      // Act
      await notificationService.initialize(userId);

      // Assert
      verify(mockFirebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      )).called(1);

      verify(mockFirebaseMessaging.getToken()).called(1);
      verify(mockFirestoreService.updateFcmToken(userId, token)).called(1);
    });

    test('onTokenRefresh updates token in firestore', () async {
      // Arrange
      const userId = 'test-user-id';
      const initialToken = 'initial-token';
      const newToken = 'new-token';

      when(mockFirebaseMessaging.requestPermission(
        alert: anyNamed('alert'),
        badge: anyNamed('badge'),
        sound: anyNamed('sound'),
        provisional: anyNamed('provisional'),
      )).thenAnswer((_) async => const NotificationSettings(
            authorizationStatus: AuthorizationStatus.authorized,
            alert: AppleNotificationSetting.enabled,
            announcement: AppleNotificationSetting.enabled,
            badge: AppleNotificationSetting.enabled,
            carPlay: AppleNotificationSetting.enabled,
            lockScreen: AppleNotificationSetting.enabled,
            notificationCenter: AppleNotificationSetting.enabled,
            showPreviews: AppleShowPreviewsSetting.always,
            sound: AppleNotificationSetting.enabled,
            timeSensitive: AppleNotificationSetting.enabled,
          ));

      when(mockFirebaseMessaging.getToken()).thenAnswer((_) async => initialToken);
      // Simulate token refresh
      when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => Stream.fromIterable([newToken]));
      when(mockFirestoreService.updateFcmToken(any, any)).thenAnswer((_) async {});

      // Act
      await notificationService.initialize(userId);

      // Wait for stream to process
      await Future.delayed(Duration.zero);

      // Assert
      verify(mockFirestoreService.updateFcmToken(userId, initialToken)).called(1);
      verify(mockFirestoreService.updateFcmToken(userId, newToken)).called(1);
    });
  });
}
