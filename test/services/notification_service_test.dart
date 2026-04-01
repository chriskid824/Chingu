import 'package:chingu/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

// Annotate mocks
@GenerateMocks([
  FirebaseMessaging,
  FirestoreService,
  FirebaseAuth,
  User,
  NotificationSettings
])
import 'notification_service_test.mocks.dart';

void main() {
  late NotificationService notificationService;
  late MockFirebaseMessaging mockFirebaseMessaging;
  late MockFirestoreService mockFirestoreService;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late MockNotificationSettings mockNotificationSettings;

  setUp(() {
    mockFirebaseMessaging = MockFirebaseMessaging();
    mockFirestoreService = MockFirestoreService();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockNotificationSettings = MockNotificationSettings();

    notificationService = NotificationService(
      firebaseMessaging: mockFirebaseMessaging,
      firestoreService: mockFirestoreService,
      firebaseAuth: mockFirebaseAuth,
    );
  });

  test('initialize requests permission and saves token if authorized', () async {
    // Arrange
    when(mockFirebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    )).thenAnswer((_) async => mockNotificationSettings);

    when(mockNotificationSettings.authorizationStatus)
        .thenReturn(AuthorizationStatus.authorized);

    when(mockFirebaseMessaging.getAPNSToken())
        .thenAnswer((_) async => 'apns_token');

    when(mockFirebaseMessaging.getToken())
        .thenAnswer((_) async => 'fcm_token');

    when(mockFirebaseMessaging.onTokenRefresh)
        .thenAnswer((_) => Stream.empty());

    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');

    // Act
    await notificationService.initialize();

    // Assert
    verify(mockFirebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    )).called(1);

    verify(mockFirebaseMessaging.getToken()).called(1);
    verify(mockFirestoreService.updateUser('test_uid', {'fcmToken': 'fcm_token'})).called(1);
  });

  test('initialize does not save token if permission denied', () async {
    // Arrange
    when(mockFirebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    )).thenAnswer((_) async => mockNotificationSettings);

    when(mockNotificationSettings.authorizationStatus)
        .thenReturn(AuthorizationStatus.denied);

    // Act
    await notificationService.initialize();

    // Assert
    verify(mockFirebaseMessaging.requestPermission(
      alert: anyNamed('alert'),
      badge: anyNamed('badge'),
      sound: anyNamed('sound'),
      provisional: anyNamed('provisional')
    )).called(1);
    verifyNever(mockFirebaseMessaging.getToken());
    verifyNever(mockFirestoreService.updateUser(any, any));
  });

  test('token refresh updates firestore', () async {
     // Arrange
     // Note: Testing private methods or event listeners added in initialize is tricky
     // without triggering the stream.

     // We can't easily trigger the private `_onTokenRefresh` without exposing it
     // or simulating the stream behavior perfectly in the `initialize` call.
     // However, we can verify that `onTokenRefresh` listener is attached.

    when(mockFirebaseMessaging.requestPermission(
      alert: anyNamed('alert'),
      badge: anyNamed('badge'),
      sound: anyNamed('sound'),
      provisional: anyNamed('provisional')
    )).thenAnswer((_) async => mockNotificationSettings);
    when(mockNotificationSettings.authorizationStatus)
        .thenReturn(AuthorizationStatus.authorized);
    when(mockFirebaseMessaging.getToken())
        .thenAnswer((_) async => 'token');
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');

    final tokenStream = Stream<String>.fromIterable(['new_token']);
    when(mockFirebaseMessaging.onTokenRefresh).thenAnswer((_) => tokenStream);

    // Act
    await notificationService.initialize();

    // We need to wait for the stream listener to process.
    await Future.delayed(Duration.zero);

    // Assert
    // Verify initial token save
    verify(mockFirestoreService.updateUser('test_uid', {'fcmToken': 'token'})).called(1);

    // Verify refresh token save
    verify(mockFirestoreService.updateUser('test_uid', {'fcmToken': 'new_token'})).called(1);
  });
}
