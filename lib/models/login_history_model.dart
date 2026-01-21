import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String location;
  final String device;
  final String ipAddress;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.location,
    required this.device,
    required this.ipAddress,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'] ?? 'Unknown Location',
      device: map['device'] ?? 'Unknown Device',
      ipAddress: map['ipAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'device': device,
      'ipAddress': ipAddress,
    };
  }
}
