import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final String uid;
  final DateTime timestamp;
  final String device;
  final String location;
  final String ipAddress;
  final String method;

  LoginHistoryModel({
    required this.id,
    required this.uid,
    required this.timestamp,
    required this.device,
    required this.location,
    required this.ipAddress,
    required this.method,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      uid: map['uid'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      device: map['device'] ?? 'Unknown Device',
      location: map['location'] ?? 'Unknown Location',
      ipAddress: map['ipAddress'] ?? '',
      method: map['method'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'timestamp': Timestamp.fromDate(timestamp),
      'device': device,
      'location': location,
      'ipAddress': ipAddress,
      'method': method,
    };
  }
}
