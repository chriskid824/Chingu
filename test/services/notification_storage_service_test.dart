import 'package:chingu/models/notification_model.dart';
import 'package:chingu/models/notification_preferences.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseAuth, User, FirestoreService])
import 'notification_storage_service_test.mocks.dart';

void main() {
  late NotificationStorageService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;
  late MockFirestoreService mockFirestoreService;

  const userId = 'test_user_id';

  final testUser = UserModel(
    uid: userId,
    name: 'Test User',
    email: 'test@example.com',
    age: 25,
    gender: 'male',
    job: 'Developer',
    interests: ['coding'],
    country: 'Taiwan',
    city: 'Taipei',
    district: 'Xinyi',
    preferredMatchType: 'any',
    minAge: 18,
    maxAge: 30,
    budgetRange: 1,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
    notificationPreferences: const NotificationPreferences(
      newMatch: true,
      newMessage: true,
      matchSuccess: true,
      eventReminder: true,
      systemUpdate: true,
    ),
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();
    mockFirestoreService = MockFirestoreService();

    // Mock Auth
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn(userId);

    // Mock FirestoreService
    when(mockFirestoreService.getUser(userId)).thenAnswer((_) async => testUser);

    service = NotificationStorageService();
    service.setFirestoreInstance(fakeFirestore);
    service.setAuthInstance(mockAuth);
    service.setFirestoreService(mockFirestoreService);
  });

  group('NotificationStorageService', () {
    test('saveNotification saves to correct path', () async {
      final notification = NotificationModel(
        id: '1',
        userId: userId,
        type: 'system',
        title: 'Test',
        message: 'Message',
        createdAt: DateTime.now(),
      );

      final id = await service.saveNotification(notification);

      expect(id, isNotEmpty);
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(id)
          .get();
      expect(snapshot.exists, true);
      expect(snapshot.data()!['title'], 'Test');
    });

    test('getNotifications returns list', () async {
      // Add data
      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'match',
        'title': 'Match',
        'message': 'Matched',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      final list = await service.getNotifications();
      expect(list.length, 1);
      expect(list.first.title, 'Match');
    });

    test('markAsRead updates isRead', () async {
      final docRef = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .add({
        'userId': userId,
        'type': 'system',
        'title': 'Test',
        'message': 'Message',
        'createdAt': DateTime.now(),
        'isRead': false,
      });

      await service.markAsRead(docRef.id);

      final snapshot = await docRef.get();
      expect(snapshot.data()!['isRead'], true);
    });

    test('shouldSendNotification respects preferences', () async {
      // User with all disabled
      final disabledUser = testUser.copyWith(
        notificationPreferences: const NotificationPreferences(
          newMatch: false,
          matchSuccess: false,
          newMessage: false,
          eventReminder: false,
          systemUpdate: false,
        ),
      );

      when(mockFirestoreService.getUser(userId)).thenAnswer((_) async => disabledUser);

      expect(await service.shouldSendNotification(userId, 'match'), false);
      expect(await service.shouldSendNotification(userId, 'message'), false);
      expect(await service.shouldSendNotification(userId, 'event'), false);
      expect(await service.shouldSendNotification(userId, 'system'), false);
    });

    test('createMatchNotification creates doc if allowed', () async {
      // Allowed by default (testUser has true)
      await service.createMatchNotification(
        matchedUserName: 'Partner',
        matchedUserId: 'partner_id',
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'match')
          .get();

      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first['message'], contains('Partner'));
    });

    test('createMatchNotification DOES NOT create doc if disabled', () async {
      final disabledUser = testUser.copyWith(
        notificationPreferences: const NotificationPreferences(
          newMatch: false,
          matchSuccess: false, // createMatchNotification checks 'match', which maps to newMatch || matchSuccess
        ),
      );
       when(mockFirestoreService.getUser(userId)).thenAnswer((_) async => disabledUser);

      await service.createMatchNotification(
        matchedUserName: 'Partner',
        matchedUserId: 'partner_id',
      );

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('type', isEqualTo: 'match')
          .get();

      expect(snapshot.docs.length, 0);
    });
  });
}
