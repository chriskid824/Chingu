import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:chingu/services/login_history_service.dart';

// Generate Mocks
@GenerateMocks([DeviceInfoPlugin, http.Client, AndroidDeviceInfo, IosDeviceInfo, WebBrowserInfo])
import 'login_history_service_test.mocks.dart';

void main() {
  late LoginHistoryService service;
  late FakeFirebaseFirestore fakeFirestore;
  late MockDeviceInfoPlugin mockDeviceInfo;
  late MockClient mockHttpClient;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockDeviceInfo = MockDeviceInfoPlugin();
    mockHttpClient = MockClient();
    service = LoginHistoryService(
      firestore: fakeFirestore,
      deviceInfo: mockDeviceInfo,
      httpClient: mockHttpClient,
    );
  });

  group('LoginHistoryService', () {
    test('recordLogin should save correct data', () async {
      final userId = 'test_user_123';

      // Mock HTTP Response
      when(mockHttpClient.get(Uri.parse('https://ipapi.co/json/'))).thenAnswer((_) async => http.Response(
        json.encode({
          'city': 'Taipei',
          'country_name': 'Taiwan',
          'ip': '1.2.3.4'
        }),
        200,
      ));

      // Mock Device Info (Even if not called due to Platform check, it's good to have)
      // Note: In unit test environment, Platform.isAndroid/iOS are false.

      await service.recordLogin(userId);

      final snapshot = await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .get();

      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['userId'], userId);
      expect(data['location'], 'Taipei, Taiwan');
      expect(data['ipAddress'], '1.2.3.4');
    });

    test('getLoginHistory should return stream of models', () async {
      final userId = 'test_user_123';

      await fakeFirestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add({
        'userId': userId,
        'timestamp': DateTime.now(),
        'deviceInfo': 'Test Device',
        'location': 'Test Location',
        'ipAddress': '1.2.3.4',
      });

      final stream = service.getLoginHistory(userId);

      expect(stream, emits(isA<List<dynamic>>()));

      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.userId, userId);
      expect(list.first.deviceInfo, 'Test Device');
    });
  });
}
