import 'package:chingu/services/notification_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_messaging_platform_interface/src/types.dart';

// Manual Mocks
class FakeUser extends Fake implements User {
  @override
  final String uid;
  FakeUser(this.uid);
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  User? _currentUser;

  void setMockUser(User? user) {
    _currentUser = user;
  }

  @override
  User? get currentUser => _currentUser;
}

class FakeFirebaseMessaging extends Fake implements FirebaseMessaging {
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async {
    return NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      sound: AppleNotificationSetting.enabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.disabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
    );
  }
}

void main() {
  late NotificationService notificationService;
  late FakeFirebaseMessaging mockMessaging;
  late FakeFirebaseFirestore fakeFirestore;
  late FakeFirebaseAuth mockAuth;
  late FakeUser mockUser;

  setUp(() {
    mockMessaging = FakeFirebaseMessaging();
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = FakeFirebaseAuth();
    mockUser = FakeUser('test_user_id');

    // Setup Auth mock
    mockAuth.setMockUser(mockUser);

    notificationService = NotificationService();
    notificationService.setDependencies(
      messaging: mockMessaging,
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('NotificationService Tracking', () {
    test('trackNotificationSend writes to Firestore', () async {
      await notificationService.trackNotificationSend(
        'notif_123',
        'match',
        'variant_A',
      );

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['notificationId'], 'notif_123');
      expect(data['type'], 'match');
      expect(data['variant'], 'variant_A');
      expect(data['action'], 'sent');
      expect(data['userId'], 'test_user_id');
    });

    test('trackNotificationClick writes to Firestore', () async {
      await notificationService.trackNotificationClick(
        'notif_456',
        'message',
        'variant_B',
      );

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['notificationId'], 'notif_456');
      expect(data['type'], 'message');
      expect(data['variant'], 'variant_B');
      expect(data['action'], 'clicked');
      expect(data['userId'], 'test_user_id');
    });

    test('trackNotificationSend does nothing if user not logged in', () async {
      mockAuth.setMockUser(null);

      await notificationService.trackNotificationSend(
        'notif_123',
        'match',
        'variant_A',
      );

      final snapshot = await fakeFirestore.collection('notification_stats').get();
      expect(snapshot.docs.length, 0);
    });
  });
}
