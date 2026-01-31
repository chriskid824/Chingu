import 'package:cloud_firestore/cloud_firestore.dart';

/// 登入歷史模型
class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String? ipAddress;
  final String? location;
  final String deviceInfo;
  final String os;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.ipAddress,
    this.location,
    required this.deviceInfo,
    required this.os,
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
      ipAddress: map['ipAddress'],
      location: map['location'],
      deviceInfo: map['deviceInfo'] ?? 'Unknown',
      os: map['os'] ?? 'Unknown',
    );
  }

  /// 轉換為 Map 以儲存到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'location': location,
      'deviceInfo': deviceInfo,
      'os': os,
    };
  }
}
