import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chingu/services/notification_service.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:chingu/services/rich_notification_service.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/notification_model.dart';

// Generate mocks
@GenerateMocks([
  FirebaseMessaging,
  FirebaseAuth,
  User,
  FirestoreService,
  NotificationStorageService,
  RichNotificationService
])
import 'notification_service_test.mocks.dart';

void main() {
  late NotificationService notificationService;
  late MockFirebaseMessaging mockMessaging;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirestoreService mockFirestoreService;
  late MockNotificationStorageService mockStorageService;
  late MockRichNotificationService mockRichNotificationService;

  setUp(() {
    mockMessaging = MockFirebaseMessaging();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestoreService = MockFirestoreService();
    mockStorageService = MockNotificationStorageService();
    mockRichNotificationService = MockRichNotificationService();

    notificationService = NotificationService();
    notificationService.setDependencies(
      messaging: mockMessaging,
      auth: mockAuth,
      firestoreService: mockFirestoreService,
      storageService: mockStorageService,
      richNotificationService: mockRichNotificationService,
    );

    // Default mock behavior
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('test_uid');
  });

  group('handleForegroundMessage', () {
    test('should show notification when preference is enabled', () async {
      // Arrange
      final userModel = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationMatches: true, // Enabled
      );

      when(mockFirestoreService.getUser('test_uid')).thenAnswer((_) async => userModel);
      when(mockStorageService.saveNotification(any)).thenAnswer((_) async => 'doc_id');
      when(mockRichNotificationService.showNotification(any)).thenAnswer((_) async {});

      final message = RemoteMessage(
        data: {
          'type': 'match',
          'title': 'New Match',
          'body': 'You have a match!',
        },
      );

      // Act
      await notificationService.handleForegroundMessage(message);

      // Assert
      verify(mockStorageService.saveNotification(any)).called(1);
      verify(mockRichNotificationService.showNotification(any)).called(1);
    });

    test('should NOT show notification when preference is disabled', () async {
      // Arrange
      final userModel = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationMatches: false, // Disabled
      );

      when(mockFirestoreService.getUser('test_uid')).thenAnswer((_) async => userModel);

      final message = RemoteMessage(
        data: {
          'type': 'match',
          'title': 'New Match',
          'body': 'You have a match!',
        },
      );

      // Act
      await notificationService.handleForegroundMessage(message);

      // Assert
      verifyNever(mockStorageService.saveNotification(any));
      verifyNever(mockRichNotificationService.showNotification(any));
    });

    test('should hide message preview when showMessagePreview is false', () async {
      // Arrange
      final userModel = UserModel(
        uid: 'test_uid',
        name: 'Test User',
        email: 'test@example.com',
        age: 25,
        gender: 'male',
        job: 'Dev',
        interests: [],
        country: 'TW',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        notificationMessages: true,
        showMessagePreview: false, // Hide preview
      );

      when(mockFirestoreService.getUser('test_uid')).thenAnswer((_) async => userModel);
      when(mockStorageService.saveNotification(any)).thenAnswer((_) async => 'doc_id');
      when(mockRichNotificationService.showNotification(any)).thenAnswer((_) async {});

      final message = RemoteMessage(
        data: {
          'type': 'message',
          'title': 'New Message',
          'body': 'Secret Content',
        },
      );

      // Act
      await notificationService.handleForegroundMessage(message);

      // Assert
      final captured = verify(mockRichNotificationService.showNotification(captureAny)).captured;
      final notification = captured.first as NotificationModel;
      expect(notification.message, '您有一則新訊息');
      expect(notification.message, isNot('Secret Content'));
    });
  });
}
