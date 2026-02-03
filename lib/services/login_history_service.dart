import 'dart:convert';
import 'dart:io';
import 'package:chingu/models/login_history_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// 記錄登入歷史
  Future<void> recordLogin(String uid, String method) async {
    try {
      final deviceData = await _getDeviceData();
      final locationData = await _getLocationData();

      final history = LoginHistoryModel(
        id: '', // Firestore will generate ID
        uid: uid,
        timestamp: DateTime.now(),
        device: deviceData,
        location: locationData['location'] ?? 'Unknown Location',
        ipAddress: locationData['ip'] ?? '',
        method: method,
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('login_history')
          .add(history.toMap());
    } catch (e) {
      debugPrint('記錄登入歷史失敗: $e');
      // 不拋出異常，以免影響登入流程
    }
  }

  /// 獲取登入歷史
  Future<List<LoginHistoryModel>> getLoginHistory(String uid) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('login_history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LoginHistoryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('獲取登入歷史失敗: $e');
      throw Exception('獲取登入歷史失敗: $e');
    }
  }

  /// 獲取設備資訊
  Future<String> _getDeviceData() async {
    try {
      if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        return '${webInfo.browserName.name} (${webInfo.platform})';
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          return '${androidInfo.manufacturer} ${androidInfo.model} (Android ${androidInfo.version.release})';
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          return '${iosInfo.name} ${iosInfo.systemName} ${iosInfo.systemVersion}';
        } else if (Platform.isMacOS) {
          final macInfo = await _deviceInfo.macOsInfo;
          return '${macInfo.model} (macOS ${macInfo.osRelease})';
        } else if (Platform.isWindows) {
          final windowsInfo = await _deviceInfo.windowsInfo;
          return '${windowsInfo.productName} (Windows)';
        } else if (Platform.isLinux) {
          final linuxInfo = await _deviceInfo.linuxInfo;
          return '${linuxInfo.name} ${linuxInfo.versionId} (Linux)';
        }
      }
      return 'Unknown Device';
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// 獲取位置資訊 (IP based)
  Future<Map<String, String>> _getLocationData() async {
    try {
      final response = await http.get(Uri.parse('https://ipwho.is/'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return {
            'location': '${data['city']}, ${data['country']}',
            'ip': data['ip'] ?? '',
          };
        }
      }
    } catch (e) {
      debugPrint('獲取位置失敗: $e');
    }
    return {
      'location': 'Unknown Location',
      'ip': '',
    };
  }
}
