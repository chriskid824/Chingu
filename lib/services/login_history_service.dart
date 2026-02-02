import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recordLogin(String userId, {String? city}) async {
    try {
      String deviceInfo = 'Unknown Device';

      if (kIsWeb) {
        deviceInfo = 'Web Browser';
      } else {
        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
            deviceInfo = 'Android Device';
            break;
          case TargetPlatform.iOS:
            deviceInfo = 'iOS Device';
            break;
          case TargetPlatform.macOS:
            deviceInfo = 'macOS Desktop';
            break;
          case TargetPlatform.windows:
            deviceInfo = 'Windows Desktop';
            break;
          case TargetPlatform.linux:
            deviceInfo = 'Linux Desktop';
            break;
          case TargetPlatform.fuchsia:
            deviceInfo = 'Fuchsia Device';
            break;
          default:
            deviceInfo = 'Unknown Platform';
        }
      }

      final history = {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'deviceInfo': deviceInfo,
        'location': city ?? 'Unknown',
        'ipAddress': 'Unknown',
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(history);
    } catch (e) {
      debugPrint('Failed to record login history: $e');
    }
  }

  Future<List<LoginHistoryModel>> getLoginHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LoginHistoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch login history: $e');
      return [];
    }
  }
}
