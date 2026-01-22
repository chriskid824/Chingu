import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/user_model.dart';
import 'package:chingu/models/login_history_model.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Records a login event for the user.
  Future<void> recordLogin(String userId, UserModel? userModel) async {
    try {
      String device = 'Unknown';
      try {
        if (Platform.isAndroid) {
          device = 'Android ${Platform.operatingSystemVersion}';
        } else if (Platform.isIOS) {
          device = 'iOS ${Platform.operatingSystemVersion}';
        } else {
          device = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
        }
      } catch (e) {
        device = 'Unknown Device';
      }

      String location = 'Unknown';

      // IP Address placeholder
      String ipAddress = 'N/A';

      final historyData = {
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': ipAddress,
        'device': device,
        'location': location,
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add(historyData);

    } catch (e) {
      debugPrint('Error recording login history: $e');
      // Fail silently as this is not critical
    }
  }

  /// Retrieves the login history for the user.
  Stream<List<LoginHistoryModel>> getLoginHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('login_history')
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to last 50 entries
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LoginHistoryModel.fromFirestore(doc))
          .toList();
    });
  }
}
