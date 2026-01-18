import 'package:cloud_firestore/cloud_firestore.dart';

class LoginHistoryModel {
  final String id;
  final DateTime timestamp;
  final String ipAddress;
  final String location;
  final String device;

  LoginHistoryModel({
    required this.id,
    required this.timestamp,
    required this.ipAddress,
    required this.location,
    required this.device,
  });

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel.fromMap(data, doc.id);
  }

  factory LoginHistoryModel.fromMap(Map<String, dynamic> data, String id) {
    return LoginHistoryModel(
      id: id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'] ?? 'Unknown',
      location: data['location'] ?? 'Unknown',
      device: data['device'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'location': location,
      'device': device,
    };
  }
}
