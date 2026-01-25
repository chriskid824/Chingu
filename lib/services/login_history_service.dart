import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore;
  final DeviceInfoPlugin _deviceInfo;

  LoginHistoryService({
    FirebaseFirestore? firestore,
    DeviceInfoPlugin? deviceInfo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// 記錄登入歷史
  Future<void> recordLogin(String userId, {String location = '未知'}) async {
    try {
      String deviceName = 'Unknown Device';
      String osVersion = 'Unknown OS';

      if (kIsWeb) {
        final webBrowserInfo = await _deviceInfo.webBrowserInfo;
        deviceName = webBrowserInfo.browserName.toString();
        osVersion = webBrowserInfo.platform ?? 'Web';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            final androidInfo = await _deviceInfo.androidInfo;
            deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
            osVersion = 'Android ${androidInfo.version.release}';
            break;
          case TargetPlatform.iOS:
            final iosInfo = await _deviceInfo.iosInfo;
            deviceName = iosInfo.name;
            osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
            break;
          case TargetPlatform.macOS:
             final macOsInfo = await _deviceInfo.macOsInfo;
             deviceName = macOsInfo.model;
             osVersion = 'macOS ${macOsInfo.osRelease}';
             break;
          case TargetPlatform.windows:
             final windowsInfo = await _deviceInfo.windowsInfo;
             deviceName = windowsInfo.computerName;
             osVersion = 'Windows';
             break;
          case TargetPlatform.linux:
             final linuxInfo = await _deviceInfo.linuxInfo;
             deviceName = linuxInfo.name;
             osVersion = '${linuxInfo.id} ${linuxInfo.versionId}';
             break;
          case TargetPlatform.fuchsia:
            break;
        }
      }

      final loginHistory = LoginHistoryModel(
        id: '', // Firestore will generate ID
        userId: userId,
        timestamp: DateTime.now(),
        deviceName: deviceName,
        osVersion: osVersion,
        location: location,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(loginHistory.toMap());
    } catch (e) {
      debugPrint('Error recording login history: $e');
      // 不拋出異常，以免影響登入流程
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
      return snapshot.docs
          .map((doc) => LoginHistoryModel.fromFirestore(doc))
          .toList();
    });
  }
}
