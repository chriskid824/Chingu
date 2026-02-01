import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore;
  final DeviceInfoPlugin _deviceInfo;
  final http.Client _httpClient;

  LoginHistoryService({
    FirebaseFirestore? firestore,
    DeviceInfoPlugin? deviceInfo,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _httpClient = httpClient ?? http.Client();

  /// 記錄登入歷史
  Future<void> recordLogin(String userId) async {
    try {
      // 並行獲取設備和位置資訊以加快速度
      final results = await Future.wait([
        _getDeviceInfo(),
        _getLocationData(),
      ]);

      final deviceInfo = results[0] as String;
      final locationData = results[1] as Map<String, String>;

      final loginHistory = {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'location': locationData['location'],
        'ipAddress': locationData['ip'],
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(loginHistory);

    } catch (e) {
      debugPrint('Error recording login history: $e');
    }
  }

  /// 獲取登入歷史列表
  Stream<List<LoginHistoryModel>> getLoginHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('login_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LoginHistoryModel.fromFirestore(doc)).toList();
    });
  }

  Future<String> _getDeviceInfo() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} on ${webInfo.platform}';
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  Future<Map<String, String>> _getLocationData() async {
    try {
      // 使用 ipapi.co 獲取位置資訊
      final response = await _httpClient.get(Uri.parse('https://ipapi.co/json/')).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes)); // 確保 UTF-8 解碼
        final city = data['city'] ?? '';
        final country = data['country_name'] ?? '';
        final ip = data['ip'] ?? '';

        String location = '';
        if (city.toString().isNotEmpty && country.toString().isNotEmpty) {
          location = '$city, $country';
        } else {
          location = country.toString().isNotEmpty ? country : city;
        }

        if (location.isEmpty) location = '未知地點';

        return {
          'location': location,
          'ip': ip.toString(),
        };
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
    }

    return {
      'location': '未知地點',
      'ip': '',
    };
  }
}
