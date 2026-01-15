import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final String deviceName;
  final String osVersion;
  final String location;
  final String ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.deviceName,
    required this.osVersion,
    required this.location,
    required this.ipAddress,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deviceName: map['deviceName'] ?? 'Unknown Device',
      osVersion: map['osVersion'] ?? 'Unknown OS',
      location: map['location'] ?? 'Unknown Location',
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceName': deviceName,
      'osVersion': osVersion,
      'location': location,
      'ipAddress': ipAddress,
    };
  }
}
