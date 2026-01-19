import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String ipAddress;
  final String deviceModel;
  final String location;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.ipAddress,
    required this.deviceModel,
    required this.location,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      ipAddress: map['ipAddress'] ?? 'Unknown IP',
      deviceModel: map['deviceModel'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown Location',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'deviceModel': deviceModel,
      'location': location,
    };
  }
}
