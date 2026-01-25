import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/services/login_history_service.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/foundation.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {
  @override
  Future<LinuxDeviceInfo> get linuxInfo => super.noSuchMethod(
        Invocation.getter(#linuxInfo),
        returnValue: Future.value(LinuxDeviceInfo(
          name: 'Linux',
          version: '1.0',
          id: 'linux',
          idLike: ['linux'],
          versionId: '1.0',
          prettyName: 'Linux',
          buildId: '1',
          variant: 'base',
          variantId: 'base',
          machineId: '1',
        )),
        returnValueForMissingStub: Future.value(LinuxDeviceInfo(
          name: 'Linux',
          version: '1.0',
          id: 'linux',
          idLike: ['linux'],
          versionId: '1.0',
          prettyName: 'Linux',
          buildId: '1',
          variant: 'base',
          variantId: 'base',
          machineId: '1',
        )),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late LoginHistoryService loginHistoryService;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    fakeFirestore = FakeFirebaseFirestore();
    loginHistoryService = LoginHistoryService(
      firestore: fakeFirestore,
      deviceInfo: MockDeviceInfoPlugin(),
    );
  });

  test('recordLogin saves data to Firestore', () async {
    const userId = 'test_user_123';

    await loginHistoryService.recordLogin(userId, location: 'Taipei');

    final snapshot = await fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('login_history')
        .get();

    expect(snapshot.docs.length, 1);
    final data = snapshot.docs.first.data();
    expect(data['userId'], userId);
    expect(data['location'], 'Taipei');
    expect(data['timestamp'], isNotNull);
    // On test runner environment, device info usually defaults to Unknown because Platform checks fail
    expect(data['deviceName'], isNotNull);
    expect(data['osVersion'], isNotNull);
  });

  test('getLoginHistory retrieves data sorted by timestamp', () async {
    const userId = 'test_user_456';
    final collection = fakeFirestore
        .collection('users')
        .doc(userId)
        .collection('login_history');

    // Add older record
    await collection.add({
      'userId': userId,
      'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'deviceName': 'Old Device',
      'osVersion': 'OS 1.0',
      'location': 'Old Loc',
    });

    // Add newer record
    await collection.add({
      'userId': userId,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'deviceName': 'New Device',
      'osVersion': 'OS 2.0',
      'location': 'New Loc',
    });

    final stream = loginHistoryService.getLoginHistory(userId);

    expect(stream, emits(isA<List<LoginHistoryModel>>()));

    final history = await stream.first;
    expect(history.length, 2);
    // Should be sorted by timestamp descending (newer first)
    expect(history[0].deviceName, 'New Device');
    expect(history[1].deviceName, 'Old Device');
  });
}
