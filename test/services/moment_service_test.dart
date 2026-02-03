import 'package:chingu/services/moment_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Create a Mock manually
class MockFirebaseStorage extends Mock implements FirebaseStorage {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;
  late MomentService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    service = MomentService(firestore: fakeFirestore, storage: mockStorage);
  });

  group('MomentService', () {
    test('getMoments returns stream of moments', () async {
      // Seed data
      await fakeFirestore.collection('moments').add({
        'userId': 'user1',
        'userName': 'User 1',
        'createdAt': Timestamp.now(),
        'imageUrls': [],
        'likeCount': 0,
      });

      final stream = service.getMoments('user1');
      final moments = await stream.first;

      expect(moments.length, 1);
      expect(moments.first.userId, 'user1');
    });

    test('deleteMoment deletes document', () async {
      final ref = await fakeFirestore.collection('moments').add({
        'userId': 'user1',
        'userName': 'User 1',
        'createdAt': Timestamp.now(),
      });

      await service.deleteMoment(ref.id);

      final doc = await fakeFirestore.collection('moments').doc(ref.id).get();
      expect(doc.exists, false);
    });
  });
}
