import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:chingu/services/moment_service.dart';
import 'package:chingu/models/moment_model.dart';
import 'dart:io';

void main() {
  late MomentService momentService;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseStorage mockStorage;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    momentService = MomentService(
      firestore: fakeFirestore,
      storage: mockStorage,
    );
  });

  group('MomentService', () {
    test('createMoment adds a moment to Firestore', () async {
      final moment = MomentModel(
        id: '1',
        userId: 'user1',
        userName: 'User One',
        content: 'Hello World',
        createdAt: DateTime.now(),
      );

      await momentService.createMoment(moment, null);

      final snapshot = await fakeFirestore.collection('moments').get();
      expect(snapshot.docs.length, 1);
      expect(snapshot.docs.first.data()['content'], 'Hello World');
      expect(snapshot.docs.first.data()['userId'], 'user1');
    });

    test('fetchMoments returns moments for a specific user', () async {
      // Add a moment for user1
      await fakeFirestore.collection('moments').add({
        'userId': 'user1',
        'userName': 'User One',
        'content': 'Moment 1',
        'createdAt': DateTime.now(),
        'likeCount': 0,
        'commentCount': 0,
      });

      // Add a moment for user2 (should not be fetched)
      await fakeFirestore.collection('moments').add({
        'userId': 'user2',
        'userName': 'User Two',
        'content': 'Moment 2',
        'createdAt': DateTime.now(),
        'likeCount': 0,
        'commentCount': 0,
      });

      final stream = momentService.fetchMoments('user1');
      final moments = await stream.first;

      expect(moments.length, 1);
      expect(moments.first.content, 'Moment 1');
      expect(moments.first.userId, 'user1');
    });

    test('likeMoment increments like count', () async {
      final ref = await fakeFirestore.collection('moments').add({
        'userId': 'user1',
        'userName': 'User One',
        'content': 'Moment 1',
        'createdAt': DateTime.now(),
        'likeCount': 0,
        'commentCount': 0,
      });

      await momentService.likeMoment(ref.id);

      final doc = await ref.get();
      expect(doc.data()?['likeCount'], 1);
    });

    test('deleteMoment removes moment from Firestore', () async {
      final ref = await fakeFirestore.collection('moments').add({
        'userId': 'user1',
        'userName': 'User One',
        'content': 'Moment 1',
        'createdAt': DateTime.now(),
        'likeCount': 0,
        'commentCount': 0,
      });

      await momentService.deleteMoment(ref.id);

      final snapshot = await fakeFirestore.collection('moments').get();
      expect(snapshot.docs.length, 0);
    });
  });
}
