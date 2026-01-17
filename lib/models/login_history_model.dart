import 'package:cloud_firestore/cloud_firestore.dart';

/// 登入歷史模型
class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String location;
  final String device;
  final String ipAddress;
  final String status; // 'success', 'failed'

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.location,
    required this.device,
    required this.ipAddress,
    this.status = 'success',
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'] ?? '',
      device: map['device'] ?? '',
      ipAddress: map['ipAddress'] ?? '',
      status: map['status'] ?? 'success',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'device': device,
      'ipAddress': ipAddress,
      'status': status,
    };
  }
}
