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

  factory LoginHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginHistoryModel(
      id: doc.id,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'] ?? 'Unknown',
      device: data['device'] ?? 'Unknown',
      ipAddress: data['ipAddress'] ?? '',
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
