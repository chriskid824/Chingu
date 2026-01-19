import 'package:chingu/services/firestore_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FirestoreService firestoreService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    firestoreService = FirestoreService(firestore: fakeFirestore);
  });

  group('Notification Settings', () {
    const userId = 'user_123';

    test('getNotificationSettings returns null when no settings exist', () async {
      final settings = await firestoreService.getNotificationSettings(userId);
      expect(settings, isNull);
    });

    test('updateNotificationSettings creates new settings', () async {
      final newSettings = {
        'push_enabled': true,
        'match_enabled': false,
      };

      await firestoreService.updateNotificationSettings(userId, newSettings);

      final settings = await firestoreService.getNotificationSettings(userId);
      expect(settings, isNotNull);
      expect(settings!['push_enabled'], true);
      expect(settings['match_enabled'], false);
    });

    test('updateNotificationSettings merges with existing settings', () async {
      // Initial setup
      await firestoreService.updateNotificationSettings(userId, {
        'push_enabled': true,
        'match_enabled': true,
      });

      // Update one field
      await firestoreService.updateNotificationSettings(userId, {
        'match_enabled': false,
      });

      final settings = await firestoreService.getNotificationSettings(userId);
      expect(settings!['push_enabled'], true); // Should remain true
      expect(settings['match_enabled'], false); // Should be updated
    });
  });
}
