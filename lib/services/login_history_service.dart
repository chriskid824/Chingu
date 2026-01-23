import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch login history for a user
  Stream<List<LoginHistoryModel>> getLoginHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('login_history')
        .orderBy('loginTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LoginHistoryModel.fromFirestore(doc)).toList();
    });
  }

  /// Record a new login
  Future<void> recordLogin(String userId, {String? city}) async {
    try {
      String deviceName = 'Unknown Device';

      if (kIsWeb) {
        deviceName = 'Web Browser';
      } else {
         if (Platform.isAndroid) {
          deviceName = 'Android Device';
        } else if (Platform.isIOS) {
          deviceName = 'iOS Device';
        } else if (Platform.isMacOS) {
          deviceName = 'Mac';
        } else if (Platform.isWindows) {
          deviceName = 'Windows';
        } else if (Platform.isLinux) {
          deviceName = 'Linux';
        }
      }

      final loginTime = DateTime.now();

      final historyData = {
        'userId': userId,
        'loginTime': Timestamp.fromDate(loginTime),
        'location': city ?? 'Unknown Location',
        'device': deviceName,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(historyData);

    } catch (e) {
      debugPrint('Failed to record login history: $e');
    }
  }
}
