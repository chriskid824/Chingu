import 'package:chingu/models/user_model.dart';
import 'package:chingu/services/firestore_service.dart';
import 'package:chingu/services/notification_storage_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Manual mock implementation since we want to avoid running build_runner
class MockFirestoreService extends Mock implements FirestoreService {
  @override
  Future<UserModel?> getUser(String uid) {
    return super.noSuchMethod(
      Invocation.method(#getUser, [uid]),
      returnValue: Future<UserModel?>.value(null),
    );
  }
}

void main() {
  late NotificationStorageService notificationService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirestoreService mockFirestoreService;

  final targetUser = UserModel(
    uid: 'target_user_id',
    name: 'Target User',
    email: 'target@test.com',
    age: 25,
    gender: 'female',
    job: 'Engineer',
    interests: [],
    country: 'Taiwan',
    city: 'Taipei',
    district: 'Xinyi',
    preferredMatchType: 'any',
    minAge: 18,
    maxAge: 30,
    budgetRange: 1,
    createdAt: DateTime.now(),
    lastLogin: DateTime.now(),
    pushNotificationsEnabled: true, // Default enabled
    notifyNewMatches: true,
    notifyNewMessages: true,
  );

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockFirestoreService = MockFirestoreService();
    notificationService = NotificationStorageService();

    // Inject dependencies
    notificationService.firestoreForTesting = fakeFirestore;
    notificationService.firestoreServiceForTesting = mockFirestoreService;
  });

  group('NotificationStorageService', () {
    test('createMatchNotification should create notification when enabled', () async {
      // Arrange
      when(mockFirestoreService.getUser(targetUser.uid))
          .thenAnswer((_) async => targetUser);

      // Act
      await notificationService.createMatchNotification(
        targetUserId: targetUser.uid,
        matchedUserName: 'Match Partner',
        matchedUserId: 'partner_id',
      );

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'match');
      expect(data['userId'], targetUser.uid);
      expect(data['title'], contains('配對成功'));
    });

    test('createMatchNotification should NOT create notification when disabled', () async {
      // Arrange
      final disabledUser = targetUser.copyWith(notifyNewMatches: false);
      when(mockFirestoreService.getUser(disabledUser.uid))
          .thenAnswer((_) async => disabledUser);

      // Act
      await notificationService.createMatchNotification(
        targetUserId: disabledUser.uid,
        matchedUserName: 'Match Partner',
        matchedUserId: 'partner_id',
      );

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(disabledUser.uid)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 0);
    });

    test('createMatchNotification should NOT create notification when push disabled globally', () async {
      // Arrange
      final disabledUser = targetUser.copyWith(pushNotificationsEnabled: false);
      when(mockFirestoreService.getUser(disabledUser.uid))
          .thenAnswer((_) async => disabledUser);

      // Act
      await notificationService.createMatchNotification(
        targetUserId: disabledUser.uid,
        matchedUserName: 'Match Partner',
        matchedUserId: 'partner_id',
      );

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(disabledUser.uid)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 0);
    });

    test('createLikeNotification should create notification', () async {
      // Arrange
      when(mockFirestoreService.getUser(targetUser.uid))
          .thenAnswer((_) async => targetUser);

      // Act
      await notificationService.createLikeNotification(
        targetUserId: targetUser.uid,
        senderName: 'Liker',
        senderId: 'liker_id',
      );

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'like');
      expect(data['message'], contains('Liker'));
    });

    test('createMessageNotification should create notification', () async {
      // Arrange
      when(mockFirestoreService.getUser(targetUser.uid))
          .thenAnswer((_) async => targetUser);

      // Act
      await notificationService.createMessageNotification(
        targetUserId: targetUser.uid,
        senderName: 'Sender',
        senderId: 'sender_id',
        messagePreview: 'Hello',
      );

      // Assert
      final snapshot = await fakeFirestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('notifications')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['type'], 'message');
      expect(data['message'], 'Hello');
    });

    test('createSystemNotification should create notification regardless of user preference check if explicitly allowed (assuming system defaults to allow)', () async {
      // Logic for system notifications: in code it calls _shouldNotify(targetUserId, 'system').
      // In _shouldNotify, default case returns true.
      // But it DOES check pushNotificationsEnabled.

      // Case 1: Enabled
      when(mockFirestoreService.getUser(targetUser.uid))
          .thenAnswer((_) async => targetUser);

      await notificationService.createSystemNotification(
        targetUserId: targetUser.uid,
        title: 'System',
        message: 'Update',
      );

      var snapshot = await fakeFirestore
          .collection('users')
          .doc(targetUser.uid)
          .collection('notifications')
          .get();
      expect(snapshot.docs.length, 1);

      // Case 2: Disabled global push
      // If pushNotificationsEnabled is false, _shouldNotify returns false.
      // So system notifications are also suppressed if push is disabled globally.
      final disabledUser = UserModel(
        uid: 'disabled_user_id',
        name: 'Disabled User',
        email: 'disabled@test.com',
        age: 25,
        gender: 'female',
        job: 'Engineer',
        interests: [],
        country: 'Taiwan',
        city: 'Taipei',
        district: 'Xinyi',
        preferredMatchType: 'any',
        minAge: 18,
        maxAge: 30,
        budgetRange: 1,
        createdAt: DateTime.now(),
        lastLogin: DateTime.now(),
        pushNotificationsEnabled: false,
        notifyNewMatches: true,
        notifyNewMessages: true,
      );
      when(mockFirestoreService.getUser(disabledUser.uid))
          .thenAnswer((_) async => disabledUser);

      await notificationService.createSystemNotification(
        targetUserId: disabledUser.uid,
        title: 'System 2',
        message: 'Update 2',
      );

       snapshot = await fakeFirestore
          .collection('users')
          .doc(disabledUser.uid)
          .collection('notifications')
          .get();
      expect(snapshot.docs.length, 0); // Suppressed
    });
  });
}
