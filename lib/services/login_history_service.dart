import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chingu/models/login_history_model.dart';

class LoginHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LoginHistoryModel>> getLoginHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => LoginHistoryModel.fromMap(doc.data(), doc.id))
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching login history: $e');
      return [];
    }
  }

  /// 記錄登入 (預留給未來整合)
  Future<void> recordLogin(String userId, String location, String device, String ip) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'location': location,
        'device': device,
        'ipAddress': ip,
      });
    } catch (e) {
      print('Error recording login: $e');
    }
  }
}
