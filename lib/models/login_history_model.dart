import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String ipAddress;
  final String location;
  final String deviceInfo;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.ipAddress,
    required this.location,
    required this.deviceInfo,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> data, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      deviceInfo: data['deviceInfo'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'location': location,
      'deviceInfo': deviceInfo,
    };
  }
}
