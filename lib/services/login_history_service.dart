import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LoginHistoryModel>> fetchLoginHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .orderBy('timestamp', descending: true)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => LoginHistoryModel.fromFirestore(doc))
            .toList();
      } else {
        // Return mock data for demonstration if no real data exists
        return _getMockData(userId);
      }
    } catch (e) {
      debugPrint('Error fetching login history: $e');
      // Fallback to mock data on error (e.g., permission issues during dev)
      return _getMockData(userId);
    }
  }

  Future<void> recordLogin(String userId, String location, String deviceInfo, {String? ipAddress}) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'location': location,
        'deviceInfo': deviceInfo,
        'ipAddress': ipAddress,
      });
    } catch (e) {
      debugPrint('Error recording login history: $e');
      rethrow;
    }
  }

  List<LoginHistoryModel> _getMockData(String userId) {
    return [
      LoginHistoryModel(
        id: '1',
        userId: userId,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        location: 'Taipei, Taiwan',
        deviceInfo: 'iPhone 13 Pro',
        ipAddress: '192.168.1.1',
      ),
      LoginHistoryModel(
        id: '2',
        userId: userId,
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        location: 'Taipei, Taiwan',
        deviceInfo: 'iPhone 13 Pro',
        ipAddress: '192.168.1.1',
      ),
      LoginHistoryModel(
        id: '3',
        userId: userId,
        timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 5)),
        location: 'New York, USA',
        deviceInfo: 'Chrome on Mac',
        ipAddress: '10.0.0.1',
      ),
      LoginHistoryModel(
        id: '4',
        userId: userId,
        timestamp: DateTime.now().subtract(const Duration(days: 7)),
        location: 'Kaohsiung, Taiwan',
        deviceInfo: 'iPad Air',
        ipAddress: '192.168.0.101',
      ),
    ];
  }
}
