import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String deviceInfo;
  final String? location;
  final String? ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.deviceInfo,
    this.location,
    this.ipAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceInfo': deviceInfo,
      'location': location,
      'ipAddress': ipAddress,
    };
  }

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deviceInfo: map['deviceInfo'] ?? 'Unknown Device',
      location: map['location'],
      ipAddress: map['ipAddress'],
    );
  }
}
