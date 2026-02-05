import 'package:cloud_firestore/cloud_firestore.dart';

/// 登入歷史記錄模型
class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String deviceModel;
  final String ipAddress;
  final String location;
  final bool isSuccess;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.deviceModel,
    required this.ipAddress,
    required this.location,
    this.isSuccess = true,
  });

  /// 從 Firestore 文檔創建 LoginHistoryModel
  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel.fromMap(data, doc.id);
  }

  /// 從 Map 創建 LoginHistoryModel
  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deviceModel: map['deviceModel'] ?? 'Unknown Device',
      ipAddress: map['ipAddress'] ?? 'Unknown IP',
      location: map['location'] ?? 'Unknown Location',
      isSuccess: map['isSuccess'] ?? true,
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceModel': deviceModel,
      'ipAddress': ipAddress,
      'location': location,
      'isSuccess': isSuccess,
    };
  }
}
