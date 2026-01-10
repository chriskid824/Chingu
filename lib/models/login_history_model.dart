import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String? id;
  final DateTime timestamp;
  final String location;
  final String device;
  final String ip;

  LoginHistoryModel({
    this.id,
    required this.timestamp,
    required this.location,
    required this.device,
    required this.ip,
  });

  factory LoginHistoryModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      location: map['location'] as String? ?? 'Unknown',
      device: map['device'] as String? ?? 'Unknown',
      ip: map['ip'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
      'device': device,
      'ip': ip,
    };
  }
}
